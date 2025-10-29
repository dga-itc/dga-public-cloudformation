# Demo: AWS CloudFormation Nested Stack

ตัวอย่างการใช้งาน **Nested Stack** ใน AWS CloudFormation แบบง่ายๆ เพื่อความเข้าใจพื้นฐาน

## 📋 สารบัญ

- [Nested Stack คืออะไร](#nested-stack-คืออะไร)
- [โครงสร้างโปรเจค](#โครงสร้างโปรเจค)
- [สถาปัตยกรรม](#สถาปัตยกรรม)
- [วิธีการใช้งาน](#วิธีการใช้งาน)
- [ทรัพยากรที่ถูกสร้าง](#ทรัพยากรที่ถูกสร้าง)
- [การลบ Stack](#การลบ-stack)
- [ข้อดีของ Nested Stack](#ข้อดีของ-nested-stack)

---

## Nested Stack คืออะไร

**Nested Stack** คือเทคนิคในการแบ่งโครงสร้าง CloudFormation ออกเป็นหลายๆ stack ย่อย โดยมี **Parent Stack** หนึ่งตัวที่ทำหน้าที่เรียกใช้ **Child Stacks** อื่นๆ

### ประโยชน์หลัก:
- **แยกความรับผิดชอบ (Separation of Concerns)**: แต่ละ stack ทำหน้าที่เฉพาะด้าน
- **นำกลับมาใช้ได้ (Reusability)**: Child templates สามารถนำไปใช้ใน project อื่นได้
- **จัดการง่าย (Maintainability)**: โค้ดสั้นลง อ่านง่ายขึ้น
- **ทำงานร่วมกันได้ (Teamwork)**: แต่ละทีมดูแล stack ของตัวเอง

---

## โครงสร้างโปรเจค

```
demo/nested-stack/
├── main-stack.yaml          # Parent Stack (เรียกใช้ child stacks ทั้งหมด)
├── network-stack.yaml       # Child Stack 1: VPC, Subnets, IGW, Route Tables
├── storage-stack.yaml       # Child Stack 2: S3 Bucket
├── security-stack.yaml      # Child Stack 3: Security Groups
└── README.md               # เอกสารนี้
```

### รายละเอียดแต่ละ Stack:

| Stack | ชื่อไฟล์ | หน้าที่ | ทรัพยากรที่สร้าง |
|-------|---------|---------|------------------|
| **Parent** | `main-stack.yaml` | เรียกใช้ child stacks ทั้งหมด | CloudFormation Nested Stacks (3 stacks) |
| **Network** | `network-stack.yaml` | จัดการเครือข่าย | VPC, Subnets (Public/Private), IGW, Route Tables |
| **Storage** | `storage-stack.yaml` | จัดการที่เก็บข้อมูล | S3 Bucket พร้อม encryption และ versioning |
| **Security** | `security-stack.yaml` | จัดการความปลอดภัย | Security Groups (Web, App, Database) |

---

## สถาปัตยกรรม

```
┌─────────────────────────────────────────────────────┐
│         Parent Stack (main-stack.yaml)              │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │   Network   │  │   Storage   │  │  Security  │ │
│  │    Stack    │  │    Stack    │  │   Stack    │ │
│  └──────┬──────┘  └─────────────┘  └─────┬──────┘ │
└─────────┼──────────────────────────────────┼────────┘
          │                                  │
          ▼                                  ▼
     VPC ID ──────────────────────────> Security Groups
                                       (ต้องการ VPC ID)
```

### ความสัมพันธ์ระหว่าง Stacks:

1. **Parent Stack** สร้าง 3 child stacks พร้อมกัน
2. **Network Stack** สร้างก่อน เพราะ **Security Stack** ต้องการ VPC ID
3. **Storage Stack** สร้างแยกอิสระ ไม่ต้องรอ stack อื่น
4. **Security Stack** ใช้ `DependsOn: NetworkStack` และรับ VPC ID ผ่าน `!GetAtt`

---

## วิธีการใช้งาน

### ขั้นตอนที่ 1: อัพโหลด Child Templates ไปยัง S3

Nested Stack ต้องการให้ child templates อยู่บน S3 เพื่อให้ Parent Stack เรียกใช้ได้

```bash
# 1. สร้าง S3 bucket (ถ้ายังไม่มี)
aws s3 mb s3://my-cloudformation-templates --region ap-southeast-1

# 2. อัพโหลด child templates
aws s3 cp network-stack.yaml s3://my-cloudformation-templates/demo/nested-stack/ --region ap-southeast-1
aws s3 cp storage-stack.yaml s3://my-cloudformation-templates/demo/nested-stack/ --region ap-southeast-1
aws s3 cp security-stack.yaml s3://my-cloudformation-templates/demo/nested-stack/ --region ap-southeast-1

# 3. ตรวจสอบว่าไฟล์อัพโหลดสำเร็จ
aws s3 ls s3://my-cloudformation-templates/demo/nested-stack/
```

**หมายเหตุ**: S3 bucket name ต้องไม่ซ้ำกันทั้ง AWS ทั้งหมด ให้เปลี่ยนเป็นชื่อที่ต้องการ

### ขั้นตอนที่ 2: สร้าง Parent Stack ผ่าน AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name demo-nested-stack \
  --template-body file://main-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=demo \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=TemplateBucketName,ParameterValue=my-cloudformation-templates \
    ParameterKey=TemplatePrefix,ParameterValue=demo/nested-stack/ \
    ParameterKey=VpcCIDR,ParameterValue=10.0.0.0/16 \
    ParameterKey=AllowedCIDR,ParameterValue=0.0.0.0/0 \
  --region ap-southeast-1
```

### ขั้นตอนที่ 3: ตรวจสอบสถานะการสร้าง Stack

```bash
# ดูสถานะ parent stack
aws cloudformation describe-stacks \
  --stack-name demo-nested-stack \
  --region ap-southeast-1 \
  --query 'Stacks[0].StackStatus'

# ดูสถานะทุก stack (รวม nested stacks)
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE CREATE_IN_PROGRESS \
  --region ap-southeast-1 \
  --query 'StackSummaries[?contains(StackName, `demo`)].{Name:StackName, Status:StackStatus}'
```

### ขั้นตอนที่ 4: ดู Outputs

```bash
# ดู outputs จาก parent stack
aws cloudformation describe-stacks \
  --stack-name demo-nested-stack \
  --region ap-southeast-1 \
  --query 'Stacks[0].Outputs'
```

---

## ทรัพยากรที่ถูกสร้าง

### 1. Network Stack
- **VPC**: 1 VPC พร้อม CIDR `10.0.0.0/16`
- **Subnets**:
  - Public Subnet (10.0.0.0/24) - มี Internet Gateway
  - Private Subnet (10.0.1.0/24)
- **Internet Gateway**: สำหรับ Public Subnet
- **Route Tables**: 2 ตัว (Public และ Private)

### 2. Storage Stack
- **S3 Bucket**:
  - Server-Side Encryption (AES256)
  - Versioning enabled
  - Public Access blocked
  - Lifecycle policy (ลบ old versions หลัง 30 วัน)

### 3. Security Stack
- **Web Server Security Group**:
  - Inbound: HTTP (80), HTTPS (443)
- **Application Security Group**:
  - Inbound: Port 8080 (จาก Web SG เท่านั้น)
- **Database Security Group**:
  - Inbound: MySQL (3306), PostgreSQL (5432) จาก App SG

---

## การลบ Stack

### วิธีที่ 1: ลบผ่าน AWS CLI

```bash
# ลบ parent stack (จะลบ child stacks อัตโนมัติ)
aws cloudformation delete-stack \
  --stack-name demo-nested-stack \
  --region ap-southeast-1

# รอจนกว่าจะลบเสร็จ
aws cloudformation wait stack-delete-complete \
  --stack-name demo-nested-stack \
  --region ap-southeast-1
```

**สำคัญ**: ถ้ามี S3 Bucket ที่มีไฟล์อยู่ การลบ stack จะล้มเหลว ต้องลบไฟล์ใน bucket ก่อน:

```bash
# ลบไฟล์ทั้งหมดใน bucket
aws s3 rm s3://demo-dev-data-<account-id> --recursive

# จากนั้นลบ stack ใหม่
aws cloudformation delete-stack --stack-name demo-nested-stack --region ap-southeast-1
```

### วิธีที่ 2: ลบผ่าน AWS Console

1. เข้า **CloudFormation Console**
2. เลือก stack `demo-nested-stack`
3. คลิก **Delete**
4. ยืนยันการลบ

---

## ข้อดีของ Nested Stack

### 1. แยกความรับผิดชอบชัดเจน (Separation of Concerns)
แต่ละ stack ทำหน้าที่เฉพาะด้าน:
- Network Stack → จัดการเครือข่าย
- Storage Stack → จัดการที่เก็บข้อมูล
- Security Stack → จัดการความปลอดภัย

### 2. นำกลับมาใช้ได้ (Reusability)
Child templates สามารถนำไปใช้ใน project อื่นได้:
```yaml
# ใช้ network-stack.yaml ใน project อื่น
NetworkStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: https://s3.../network-stack.yaml
    Parameters:
      ProjectName: another-project
```

### 3. หลีกเลี่ยง Template Limit (200 resources/template)
CloudFormation จำกัด 1 template ไม่เกิน 200 resources การแบ่งเป็น nested stacks ช่วยแก้ปัญหานี้

### 4. Update แบบเฉพาะส่วน
Update เฉพาะ stack ที่ต้องการโดยไม่กระทบส่วนอื่น:
```bash
# Update เฉพาะ security stack
aws cloudformation update-stack \
  --stack-name demo-nested-stack-SecurityStack-XXXXX \
  --template-body file://security-stack.yaml
```

### 5. ทำงานเป็นทีมได้ง่าย
แต่ละทีมดูแล stack ของตัวเอง:
- Network Team → `network-stack.yaml`
- Security Team → `security-stack.yaml`
- Storage Team → `storage-stack.yaml`

### 6. แชร์ค่าระหว่าง Stacks (Cross-Stack References)
ใช้ `!GetAtt` ส่งค่าระหว่าง stacks:
```yaml
# Parent Stack รับ VPC ID จาก Network Stack
VpcId: !GetAtt NetworkStack.Outputs.VPCId

# ส่งต่อให้ Security Stack
SecurityStack:
  Parameters:
    VpcId: !GetAtt NetworkStack.Outputs.VPCId
```

---

## ตัวอย่างการทำงาน

### สถานการณ์: อัพเดต Security Group

สมมติต้องการเปิด port 22 (SSH) ใน Web Server Security Group:

1. แก้ไข `security-stack.yaml`:
```yaml
SecurityGroupIngress:
  # เพิ่ม SSH rule
  - IpProtocol: tcp
    FromPort: 22
    ToPort: 22
    CidrIp: !Ref AllowedCIDR
    Description: 'Allow SSH'
```

2. อัพโหลด template ใหม่ไปยัง S3:
```bash
aws s3 cp security-stack.yaml s3://my-cloudformation-templates/demo/nested-stack/
```

3. Update parent stack:
```bash
aws cloudformation update-stack \
  --stack-name demo-nested-stack \
  --template-body file://main-stack.yaml \
  --parameters ... \
  --region ap-southeast-1
```

CloudFormation จะ update เฉพาะ Security Stack เท่านั้น ไม่กระทบ Network และ Storage Stack

---

## ข้อควรระวัง

### 1. S3 Template URLs ต้องเข้าถึงได้
- Templates ต้องอยู่บน S3 และ CloudFormation ต้องเข้าถึงได้
- ถ้า S3 bucket เป็น private ต้องตั้งค่า permissions ให้ถูกต้อง

### 2. Circular Dependencies
หลีกเลี่ยงการอ้างอิงวนกลับ:
```yaml
# ❌ ผิด: Stack A ต้องการ Stack B และ Stack B ต้องการ Stack A
StackA:
  Parameters:
    ValueFromB: !GetAtt StackB.Outputs.Value

StackB:
  Parameters:
    ValueFromA: !GetAtt StackA.Outputs.Value
```

### 3. Update Policy
- Update parent stack จะ update child stacks ที่มีการเปลี่ยนแปลงเท่านั้น
- ถ้า child template URL เดิม แต่เนื้อหาใน S3 เปลี่ยน ต้อง force update หรือเปลี่ยน URL

### 4. Delete Behavior
- ลบ parent stack จะลบ child stacks ทั้งหมดอัตโนมัติ
- ถ้า child stack มี resources ที่มี `DeletionPolicy: Retain` จะไม่ถูกลบ

---

## เอกสารเพิ่มเติม

- [AWS CloudFormation Nested Stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html)
- [AWS::CloudFormation::Stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html)
- [Best Practices for CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)

---

## License

ตัวอย่างนี้เป็น public domain สามารถนำไปใช้ได้เลยโดยไม่มีข้อจำกัด
