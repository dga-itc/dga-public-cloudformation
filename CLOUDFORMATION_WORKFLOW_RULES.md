# CloudFormation Template Workflow Rules

## 🚨 **กฎบังคับเมื่อสร้าง CloudFormation Template ใหม่**

### **Rule 1: Template Creation Checklist**

เมื่อสร้าง CloudFormation template ใหม่ **ต้องทำครบทุกขั้นตอน:**

#### **✅ Step 1: Create CloudFormation Template**
- [ ] สร้าง template ตาม `CLOUDFORMATION_TEMPLATE_STANDARDS.md`
- [ ] ตั้งชื่อไฟล์: `[service-name]-v1.0.yaml`
- [ ] ใส่ standard parameters ครบถ้วน
- [ ] เพิ่ม import mode (ถ้ามี dependencies)
- [ ] กำหนด exports ตาม naming convention

#### **✅ Step 2: Create Deploy Playbook**
- [ ] สร้าง `ansible/playbooks/deploy/[service-name].yml`
- [ ] ใช้ template structure ตาม `PLAYBOOK_STANDARD.md`
- [ ] เพิ่ม parameters และ tags ที่ถูกต้อง
- [ ] Test deploy playbook

#### **✅ Step 3: Create Destroy Playbook**
- [ ] สร้าง `ansible/playbooks/destroy/[service-name].yml`
- [ ] ใช้ `state: absent` และ `ignore_errors: true`
- [ ] ใช้ stack name เดียวกับ deploy playbook
- [ ] Test destroy playbook

#### **✅ Step 4: Update Main Playbooks**
- [ ] เพิ่ม task ใน `deploy-infrastructure.yml`
- [ ] เพิ่ม task ใน `destroy-infrastructure.yml` (reverse order)
- [ ] กำหนด tags ที่เหมาะสม
- [ ] ตรวจสอบ dependency order

#### **✅ Step 5: Update Template Versions**
- [ ] เพิ่ม template path ใน `vars/template-versions.yml`
- [ ] อัพเดท version tracking

#### **✅ Step 6: Update Variables**
- [ ] เพิ่มตัวแปรใน `vars/development.yml`
- [ ] เพิ่มตัวแปรใน `vars/production.yml` (ถ้าใช้)
- [ ] ตรวจสอบ variable consistency

#### **✅ Step 7: Documentation**
- [ ] อัพเดท `README.md` หรือ relevant docs
- [ ] เพิ่ม service ใน architecture diagram
- [ ] Document dependencies และ configuration

#### **✅ Step 8: Validation (ไม่ต้อง Deploy จริง)**
- [ ] CloudFormation template validation
- [ ] Ansible playbook syntax check
- [ ] Ansible dry-run validation
- [ ] Template standards compliance check

### **Rule 2: Template Modification**

เมื่อแก้ไข template ที่มีอยู่:

#### **✅ Version Update Required**
- [ ] Copy template เป็น version ใหม่ (v1.0 → v1.1)
- [ ] อัพเดท `template-versions.yml`
- [ ] เก็บ version เก่าไว้ (backward compatibility)
- [ ] Document breaking changes

#### **✅ Playbook Update**
- [ ] อัพเดท deploy playbook ให้ใช้ template version ใหม่
- [ ] Test การเปลี่ยนแปลง
- [ ] ตรวจสอบ parameters ใหม่

### **Rule 3: Validation Requirements**

#### **✅ Pre-Deployment Validation (ไม่ Deploy จริง)**
```bash
# CloudFormation Template Validation
aws cloudformation validate-template \
  --template-body file://cloudformation/[service]/[template].yaml

# 4. Template Standards Check
# ใช้ AI Assistant ตรวจสอบตาม CLOUDFORMATION_TEMPLATE_STANDARDS.md
```

### **Rule 4: Rollback Plan**

#### **✅ Before Deployment**
- [ ] มี rollback plan ชัดเจน
- [ ] Test destroy playbook ก่อน
- [ ] Backup configuration ที่สำคัญ
- [ ] กำหนด rollback criteria

### **Rule 5: Approval Process**

#### **✅ Required Approvals**
- [ ] **New Template**: ต้องได้รับอนุญาติก่อนสร้าง
- [ ] **Template Modification**: ต้องได้รับอนุญาติก่อนแก้ไข
- [ ] **Production Deployment**: ต้องผ่าน dev testing ก่อน

#### **✅ Approval Format**
```markdown
## 🚨 **CloudFormation Template Request**

### **Action**: [CREATE_NEW | MODIFY_EXISTING]
### **Template**: [template-name-v1.0.yaml]
### **Service**: [service-description]

### **Changes**:
- [รายการการเปลี่ยนแปลง]
- [Resources ใหม่]
- [Dependencies]

### **Impact**:
- [ผลกระทบต่อ existing resources]
- [Downtime requirements]

### **Testing Plan**:
- [ ] Deploy testing completed
- [ ] Destroy testing completed
- [ ] Integration testing completed

### **Rollback Plan**:
- [วิธี rollback หากมีปัญหา]

**Request Permission to Proceed?**
```

## 🎯 **Enforcement**

### **🚨 Mandatory Compliance**
- **ไม่อนุญาต** deploy template ที่ไม่ผ่าน checklist
- **ไม่อนุญาต** skip ขั้นตอนใดๆ
- **บังคับ** ต้องมี destroy playbook ก่อน deploy

### **✅ Quality Gates**
1. **Template Standards Compliance** - ต้องผ่าน 100%
2. **Playbook Standards Compliance** - ต้องผ่าน 100%
3. **Testing Requirements** - ต้อง test ทั้ง deploy และ destroy
4. **Documentation Updates** - ต้องอัพเดทเอกสาร

---

**Document Version**: 1.0  
**Effective Date**: January 2025  
**Compliance**: Mandatory for all CloudFormation development
