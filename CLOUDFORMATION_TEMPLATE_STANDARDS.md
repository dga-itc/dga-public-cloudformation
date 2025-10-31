# CloudFormation Template Standards & Validation

## 📋 **ข้อบังคับในการเขียน CloudFormation Template**

### **Rule 1: Standard Parameters (บังคับทุก Template)**

#### **✅ Required Parameters**
```yaml
Parameters:
  ProjectName:
    Type: String
    Description: "Project identifier"
  
  Environment:
    Type: String
    Description: "Environment identifier"
    AllowedValues: ["dev", "sit", "uat", "pvt", "pre-prod", "prod"]
  
  UniqueStackName:
    Type: String
    Description: "Unique identifier for this stack"
    Default: "[service-name]"
  
  CostCenter:
    Type: String
    Description: "Cost center for billing"
    Default: "IT"
```

### **Rule 1.5: Export Stack Parameters (บังคับสำหรับ Template ที่มี Import)**

#### **✅ New Pattern: Export Stack Parameters**
แทนที่การใช้ `ProjectName + Environment + StackUniqueName` ให้ใช้ Export Stack Parameter:

```yaml
# OLD Pattern (ไม่ใช้แล้ว)
VPCStackUniqueName:
  Type: String
  Default: "main-vpc"

# NEW Pattern (ใช้แทน)
VPCExportStack:
  Type: String
  Description: "VPC stack name to import from"
  Default: "lab-iac-prod-main-vpc"
```

#### **✅ Common Export Stack Parameters**
```yaml
# สำหรับ Template ที่ import จาก stack อื่น
VPCExportStack:
  Type: String
  Description: "VPC stack name to import from"
  Default: "lab-iac-prod-main-vpc"

EIPExportStack:
  Type: String  
  Description: "EIP stack name to import from"
  Default: "lab-iac-prod-eip-nlb"

ALBExportStack:
  Type: String
  Description: "ALB stack name to import from" 
  Default: "lab-iac-prod-alb"

ECSExportStack:
  Type: String
  Description: "ECS cluster stack name to import from"
  Default: "lab-iac-prod-ecs-cluster"

IAMExportStack:
  Type: String
  Description: "IAM roles stack name to import from"
  Default: "lab-iac-prod-iam-roles"

EFSExportStack:
  Type: String
  Description: "EFS stack name to import from"
  Default: "lab-iac-prod-efs"
```

### **Rule 1.6: Import Pattern (บังคับใหม่)**

#### **✅ New Import Pattern**
```yaml
# OLD (ไม่ใช้แล้ว)
!ImportValue 
  Fn::Sub: '${ProjectName}-${Environment}-${VPCStackUniqueName}-Id'

# NEW (ใช้แทน)
!ImportValue 
  Fn::Sub: '${VPCExportStack}-Id'
```

### **Rule 1.7: Parameter Organization (บังคับทุก Template)**

#### **✅ Required Metadata Section**
```yaml
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: "Project Information"
        Parameters:
          - ProjectName
          - Environment
          - UniqueStackName
          - CostCenter
      - Label:
          default: "Network Configuration"
        Parameters:
          - [NetworkSpecificParameters]
      - Label:
          default: "Service Configuration"
        Parameters:
          - [ServiceSpecificParameters]
      - Label:
          default: "Stack Dependencies"
        Parameters:
          - [StackUniqueName parameters]
      - Label:
          default: "Import Configuration"
        Parameters:
          - [ImportMode and Manual parameters]
    ParameterLabels:
      ProjectName:
        default: "Project Name"
      Environment:
        default: "Environment"
      UniqueStackName:
        default: "Stack Unique Name"
      CostCenter:
        default: "Cost Center"
```

#### **✅ Standard Parameter Groups**
1. **Project Information** (บังคับ)
   - ProjectName, Environment, UniqueStackName, CostCenter

2. **VPC CIDR Configuration** (สำหรับ VPC templates)
   - VpcCidr, SecondaryCidr

3. **Public Subnets** (สำหรับ VPC templates)
   - PublicSubnet1Cidr, PublicSubnet2Cidr, PublicSubnet3Cidr

4. **Private Subnets** (สำหรับ VPC templates)
   - PrivateSubnet1Cidr, PrivateSubnet2Cidr, PrivateSubnet3Cidr

5. **Container Subnets** (สำหรับ VPC templates)
   - ContainerSubnet1Cidr, ContainerSubnet2Cidr

6. **Database Subnets** (สำหรับ VPC templates)
   - DatabaseSubnet1Cidr, DatabaseSubnet2Cidr, DatabaseSubnet3Cidr

7. **Network Configuration** (สำหรับ service templates)
   - Network-related parameters (ports, protocols, CIDR blocks)

8. **Service Configuration** (สำหรับ service templates)
   - Service-specific parameters (instance types, capacity, features)

9. **Stack Dependencies** (ถ้ามี stack references)
   - VPCStackUniqueName, EIPStackUniqueName, ALBStackUniqueName

10. **Import Configuration** (ถ้ามี import modes)
    - ImportMode parameters และ manual override parameters

#### **✅ VPC Template Example**
```yaml
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: "Project Information"
        Parameters:
          - ProjectName
          - Environment
          - UniqueStackName
      - Label:
          default: "VPC CIDR Configuration"
        Parameters:
          - VpcCidr
          - SecondaryCidr
      - Label:
          default: "Public Subnets"
        Parameters:
          - PublicSubnet1Cidr
          - PublicSubnet2Cidr
      - Label:
          default: "Private Subnets"
        Parameters:
          - PrivateSubnet1Cidr
          - PrivateSubnet2Cidr
      - Label:
          default: "Container Subnets"
        Parameters:
          - ContainerSubnet1Cidr
          - ContainerSubnet2Cidr
      - Label:
          default: "Database Subnets"
        Parameters:
          - DatabaseSubnet1Cidr
          - DatabaseSubnet2Cidr
          - DatabaseSubnet3Cidr
      - Label:
          default: "Stack Dependencies"
        Parameters:
          - EIPStackUniqueName
      - Label:
          default: "Import Configuration"
        Parameters:
          - EIPImportMode
          - EIP1AllocationId
          - EIP2AllocationId
```

#### **✅ Service Template Example**
```yaml
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: "Project Information"
        Parameters:
          - ProjectName
          - Environment
          - UniqueStackName
          - CostCenter
      - Label:
          default: "Network Configuration"
        Parameters:
          - ContainerPort
          - HealthCheckPath
          - PathPattern
      - Label:
          default: "Service Configuration"
        Parameters:
          - ContainerName
          - ContainerImage
          - ContainerCpu
          - ContainerMemory
          - DesiredCount
      - Label:
          default: "Stack Dependencies"
        Parameters:
          - VPCStackUniqueName
          - ECSClusterStackUniqueName
          - ALBStackUniqueName
```

### **Rule 2: Import Mode Support (สำหรับ Stack ที่มี Dependencies)**

#### **✅ Dependency Stack Parameters**
```yaml
  # Import Mode Configuration
  VPCImportMode:
    Type: String
    Description: "How to get VPC and Subnet IDs"
    AllowedValues: ["AUTO", "MANUAL"]
    Default: "AUTO"
  
  # Dependency Stack Reference
  VPCStackUniqueName:
    Type: String
    Description: "VPC stack unique name to import from"
    Default: "main-vpc"
  
  # Manual Mode Parameters (empty defaults)
  VpcId:
    Type: String
    Description: "VPC ID (only if VPCImportMode=MANUAL)"
    Default: ""
  
  PrivateSubnetId1:
    Type: String
    Description: "Private Subnet 1 ID (only if VPCImportMode=MANUAL)"
    Default: ""
  
  PrivateSubnetId2:
    Type: String
    Description: "Private Subnet 2 ID (only if VPCImportMode=MANUAL)"
    Default: ""
```

#### **✅ Required Conditions**
```yaml
Conditions:
  UseManualVPC: !Equals [!Ref VPCImportMode, "MANUAL"]
```

#### **✅ Conditional Resource Properties**
```yaml
Resources:
  MyResource:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !If
        - UseManualVPC
        - !Ref VpcId
        - !ImportValue 
            Fn::Sub: '${ProjectName}-${Environment}-${VPCStackUniqueName}-Id'
      # Other properties...
```

### **Rule 3: Standard Outputs with Export**

#### **✅ Required Stack Name Output (บังคับทุก Template ที่มี Export)**
```yaml
Outputs:
  StackName:
    Description: "Stack Name for cross-stack references"
    Value: !Sub "${ProjectName}-${Environment}-${UniqueStackName}"
    Export:
      Name: !Sub "${ProjectName}-${Environment}-${UniqueStackName}"
```

#### **✅ Export Naming Convention**
```yaml
Export:
  Name: !Sub '${ProjectName}-${Environment}-${UniqueStackName}-{ResourceType}-{Attribute}'
```

#### **✅ Common Resource Types & Attributes**

| AWS Resource | ResourceType | Common Attributes |
|--------------|--------------|-------------------|
| VPC | `VPC` | `Id` |
| Subnet | `Subnet` | `Id` |
| Security Group | `SecurityGroup` | `Id` |
| Load Balancer | `ALB`, `NLB` | `Arn`, `DNSName`, `ZoneId` |
| Target Group | `TargetGroup` | `Arn` |
| Listener | `Listener` | `Arn` |
| EIP | `EIP` | `AllocationId` |
| ECS Cluster | `Cluster` | `Id`, `Arn`, `Name` |
| ECR Repository | `Repository` | `Arn`, `RepositoryUri` |
| ElastiCache | `Cache` | `Id`, `Endpoint` |

#### **✅ Standard Output Examples**
```yaml
Outputs:
  ResourceId:
    Description: "[Resource Type] ID"
    Value: !Ref Resource
    Export:
      Name: !Sub '${ProjectName}-${Environment}-${UniqueStackName}-Id'
  
  ResourceArn:
    Description: "[Resource Type] ARN"
    Value: !GetAtt Resource.Arn
    Export:
      Name: !Sub '${ProjectName}-${Environment}-${UniqueStackName}-Arn'
```

#### **✅ Stack Naming Examples**

| Stack Purpose | UniqueStackName | Full Export Example |
|---------------|-----------------|-------------------|
| Main VPC | `main-vpc` | `lab-iac-dev-main-vpc-Id` |
| Internal ALB | `internal-alb` | `lab-iac-dev-internal-alb-Arn` |
| Private NLB | `nlb-private-apigw` | `lab-iac-dev-nlb-private-apigw-DNSName` |
| ECS Cluster | `ecs-cluster` | `lab-iac-dev-ecs-cluster-Arn` |
| NAT Gateway EIPs | `natgw-eip` | `lab-iac-dev-natgw-eip-EIP1-AllocationId` |

### **Rule 4: Template Versioning**

#### **✅ File Naming Convention**
- Format: `[service-name]-v[major].[minor].yaml`
- Examples: `vpc-v1.0.yaml`, `alb-v1.1.yaml`

#### **✅ Version Documentation**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: '[Service Name] Stack v[version] - [Brief Description]'

Metadata:
  Version: "v1.0"
  LastUpdated: "2025-01-01"
  BreakingChanges: "None"
```

### **Rule 5: Stack Categories & Deployment Order**

#### **✅ True Foundation Stacks (ไม่ต้อง Import Mode)**
1. **EIP** - No dependencies
2. **IAM Roles** - No dependencies
3. **Route53 Hosted Zones** - No dependencies

#### **✅ Infrastructure Foundation (ต้องมี Import Mode)**
4. **VPC** → EIP (depends on EIP stack)

#### **✅ Service Layer Stacks (ต้องมี Import Mode)**
5. **ALB** → VPC
6. **NLB** → VPC + ALB
7. **ECS Cluster** → VPC
8. **ECS Services** → VPC + ALB + ECS Cluster
9. **EFS** → VPC
10. **ElastiCache** → VPC
11. **API Gateway** → VPC + ALB + NLB
12. **SQS** → (optional VPC for VPC endpoints)
13. **ECR** → (standalone but may need VPC for endpoints)

#### **✅ Environment Definitions**

| Environment | Purpose | Description |
|-------------|---------|-------------|
| `dev` | Development | Developer testing and feature development |
| `sit` | System Integration Test | Integration testing environment |
| `uat` | User Acceptance Test | Business user testing environment |
| `pvt` | Performance/Volume Test | Load and performance testing |
| `pre-prod` | Pre-Production | Production-like environment for final testing |
| `prod` | Production | Live production environment |

### **Rule 6: Resource Support Matrix & Policy Standards**

#### **📊 Project Resource Support Matrix (34 Resource Types)**

| **Resource Type** | **DeletionPolicy** | **UpdateReplacePolicy** | **Snapshot Support** | **Critical Level** |
|-------------------|-------------------|------------------------|---------------------|-------------------|

##### **🌐 API Gateway (6 types)**
| **AWS::ApiGateway::Deployment** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ApiGateway::Method** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::ApiGateway::Resource** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::ApiGateway::RestApi** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ApiGateway::Stage** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::ApiGateway::VpcLink** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |

##### **📊 Monitoring (1 type)**
| **AWS::CloudWatch::Alarm** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |

##### **🌍 Networking - EC2 (10 types)**
| **AWS::EC2::EIP** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🔴 High |
| **AWS::EC2::InternetGateway** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EC2::NatGateway** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EC2::Route** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::EC2::RouteTable** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::EC2::SecurityGroup** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EC2::SecurityGroupIngress** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::EC2::Subnet** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EC2::SubnetRouteTableAssociation** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::EC2::VPC** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🔴 High |
| **AWS::EC2::VPCCidrBlock** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EC2::VPCGatewayAttachment** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |

##### **📦 Container Services (4 types)**
| **AWS::ECR::Repository** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🔴 High |
| **AWS::ECS::Cluster** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ECS::Service** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ECS::TaskDefinition** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |

##### **💾 Storage (3 types)**
| **AWS::EFS::AccessPoint** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::EFS::FileSystem** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🔴 High |
| **AWS::EFS::MountTarget** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |

##### **⚡ Cache (1 type)**
| **AWS::ElastiCache::ServerlessCache** | ✅ All | ✅ Delete/Retain | ❌ | 🔴 High |

##### **⚖️ Load Balancing (4 types)**
| **AWS::ElasticLoadBalancingV2::Listener** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ElasticLoadBalancingV2::ListenerRule** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟢 Low |
| **AWS::ElasticLoadBalancingV2::LoadBalancer** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |
| **AWS::ElasticLoadBalancingV2::TargetGroup** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |

##### **🔐 Security (1 type)**
| **AWS::IAM::Role** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |

##### **📝 Logging (1 type)**
| **AWS::Logs::LogGroup** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🔴 High |

##### **🌐 DNS (1 type)**
| **AWS::Route53::RecordSet** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |

##### **📬 Messaging (1 type)**
| **AWS::SQS::Queue** | ✅ Delete/Retain | ✅ Delete/Retain | ❌ | 🟡 Medium |

#### **🚨 Key Findings:**
- **Snapshot-Capable Resources:** 0 resources (ElastiCache Serverless ไม่รองรับ Snapshot)
- **Delete/Retain Only:** 34 resources (100%)
- **Critical Resources:** 6 resources ควร Retain ใน Production

### **Rule 7: Standard Resource Tagging**

#### **✅ Required Tags (ทุก Resource)**
```yaml
Tags:
  - Key: Project
    Value: !Ref ProjectName
  - Key: Environment
    Value: !Ref Environment
  - Key: CostCenter
    Value: !Ref CostCenter
  - Key: ManagedBy
    Value: "CloudFormation"
```

#### **✅ Extended Tags (แนะนำ)**
```yaml
  - Key: Owner
    Value: !Ref Owner
  - Key: BusinessUnit
    Value: !Ref BusinessUnit
  - Key: ContactEmail
    Value: !Ref ContactEmail
  - Key: DataClassification
    Value: !Ref DataClassification
  - Key: Application
    Value: !Ref Application
  - Key: Compliance
    Value: !Ref Compliance
```

#### **✅ Tag Parameters (เพิ่มใน Parameters section)**
```yaml
Parameters:
  # ... standard parameters ...
  
  # Extended Tag Parameters
  Owner:
    Type: String
    Description: "Team/person responsible"
    Default: "DevOps Team"
  
  BusinessUnit:
    Type: String
    Description: "Department"
    Default: "IT"
  
  ContactEmail:
    Type: String
    Description: "Contact email"
    Default: "devops@company.com"
  
  DataClassification:
    Type: String
    Description: "Security classification"
    AllowedValues: ["Public", "Internal", "Confidential", "Restricted"]
    Default: "Internal"
  
  Application:
    Type: String
    Description: "Application name"
    Default: ""
  
  Compliance:
    Type: String
    Description: "Compliance requirement"
    Default: ""
```

### **Rule 8: Parameter Update Behavior Documentation (บังคับทุก Parameter)**

#### **✅ Required Description Format**
```yaml
Parameters:
  ParameterName:
    Type: String
    Description: "Parameter description (Update requires: [BEHAVIOR])"
```

#### **✅ Update Behavior Categories**
- **No interruption**: Safe updates, no downtime
- **Some interruption**: Rolling updates, minimal downtime  
- **Replacement - zero downtime**: Resource replacement with mitigation
- **Replacement - potential downtime**: Dangerous updates
- **Replacement - creates new resource**: Complete resource recreation

#### **✅ Common Parameter Update Behaviors**
| **Parameter Type** | **Update Behavior** | **Description Format** |
|-------------------|-------------------|----------------------|
| ContainerCpu/Memory | No interruption | "(Update requires: No interruption)" |
| DesiredCount | No interruption | "(Update requires: No interruption)" |
| ContainerImage | Some interruption | "(Update requires: Some interruption - rolling update)" |
| ContainerPort | Replacement | "(Update requires: Replacement - zero downtime with port-based TG naming)" |
| ContainerName | Replacement | "(Update requires: Replacement - creates new service)" |
| VpcCidr | Replacement | "(Update requires: Replacement - creates new VPC)" |
| UniqueStackName | Replacement | "(Update requires: Replacement - changes resource names)" |

#### **✅ Example Implementation**
```yaml
Parameters:
  ContainerPort:
    Type: Number
    Description: "Container port (Update requires: Replacement - zero downtime with port-based TG naming)"
    Default: 80
  
  ContainerCpu:
    Type: Number
    Description: "CPU units for container (Update requires: No interruption)"
    Default: 256
  
  VpcCidr:
    Type: String
    Description: "VPC CIDR block (Update requires: Replacement - creates new VPC)"
    Default: "10.0.0.0/16"
```

### **Rule 9: Policy Parameters Standards (บังคับทุก Template)**

#### **✅ Required Policy Parameters**
```yaml
Parameters:
  # ... existing parameters ...
  
  ResourceDeletionPolicy:
    Type: String
    Description: "Resource deletion policy on stack deletion (Update requires: No interruption)"
    AllowedValues: ["Delete", "Retain", "Snapshot"]
    Default: "Delete"
  
  ResourceUpdateReplacePolicy:
    Type: String
    Description: "Resource update replacement policy during updates (Update requires: No interruption)"
    AllowedValues: ["Delete", "Retain", "Snapshot"]
    Default: "Delete"

Conditions:
  ShouldRetainOnDelete: !Equals [!Ref ResourceDeletionPolicy, "Retain"]
  ShouldSnapshotOnDelete: !Equals [!Ref ResourceDeletionPolicy, "Snapshot"]
  ShouldRetainOnReplace: !Equals [!Ref ResourceUpdateReplacePolicy, "Retain"]
  ShouldSnapshotOnReplace: !Equals [!Ref ResourceUpdateReplacePolicy, "Snapshot"]
```

#### **✅ Resource Implementation Patterns**

##### **Snapshot-Capable Resources (ElastiCache เท่านั้น):**
```yaml
Resources:
  ServerlessCache:
    Type: AWS::ElastiCache::ServerlessCache
    DeletionPolicy: !If
      - ShouldRetainOnDelete
      - Retain
      - !If [ShouldSnapshotOnDelete, Snapshot, Delete]
    UpdateReplacePolicy: !If
      - ShouldRetainOnReplace
      - Retain
      - !If [ShouldSnapshotOnReplace, Snapshot, Delete]
```

##### **Delete/Retain Only Resources (ทุกอย่างอื่น):**
```yaml
Resources:
  MyResource:
    Type: AWS::EC2::VPC  # หรือ resource อื่นๆ
    DeletionPolicy: !If [ShouldRetainOnDelete, Retain, Delete]
    UpdateReplacePolicy: !If [ShouldRetainOnReplace, Retain, Delete]
    # ไม่ใช้ Snapshot เพราะไม่รองรับ
```

#### **✅ Usage Examples**
```bash
# Development (default)
--parameters ParameterKey=ResourceDeletionPolicy,ParameterValue=Delete

# Production
--parameters ParameterKey=ResourceDeletionPolicy,ParameterValue=Retain

# ElastiCache with snapshots
--parameters ParameterKey=ResourceDeletionPolicy,ParameterValue=Snapshot
```

### **Rule 10: Target Group Special Rules (บังคับ)**

#### **✅ Port-Based Naming (บังคับทุก Target Group)**
```yaml
TargetGroup:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  Properties:
    Name: !Sub "${ProjectName}-${Environment}-${UniqueStackName}-tg-${ContainerPort}"
    Port: !Ref ContainerPort
    Protocol: HTTP
```

#### **✅ Policy Override (บังคับทุก Target Group)**
```yaml
TargetGroup:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  DeletionPolicy: !If [ShouldRetainOnDelete, Retain, Delete]
  UpdateReplacePolicy: Retain  # ALWAYS Retain - ignore parameter
  Properties:
    Name: !Sub "${ProjectName}-${Environment}-${UniqueStackName}-tg-${ContainerPort}"
```

#### **✅ NLB Target Group Examples**
```yaml
NLBTargetGroupHTTP:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  DependsOn: NetworkLoadBalancer
  DeletionPolicy: !If [ShouldRetainOnDelete, Retain, Delete]
  UpdateReplacePolicy: Retain  # ALWAYS Retain
  Properties:
    Name: !Sub "${ProjectName}-${Environment}-${UniqueStackName}-tg-80"
    Port: 80
    Protocol: TCP

NLBTargetGroupHTTPS:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  DependsOn: NetworkLoadBalancer
  DeletionPolicy: !If [ShouldRetainOnDelete, Retain, Delete]
  UpdateReplacePolicy: Retain  # ALWAYS Retain
  Properties:
    Name: !Sub "${ProjectName}-${Environment}-${UniqueStackName}-tg-443"
    Port: 443
    Protocol: TCP
```

#### **✅ Benefits**
- **Zero Downtime Port Changes**: Port-based naming + Retain policy
- **Flexible Deletion**: Parameter-driven DeletionPolicy
- **Consistent Behavior**: All Target Groups follow same pattern

### **Rule 11: Required Tag Parameters**

#### **✅ Minimum Tag Parameters (บังคับ)**
```yaml
Parameters:
  # ... standard parameters ...
  
  CostCenter:
    Type: String
    Description: "Cost center for billing"
    Default: "IT"
```

#### **✅ Resource Tagging (ใช้ parameters)**
```yaml
Resources:
  MyResource:
    Type: AWS::EC2::VPC
    Properties:
      Tags:
        - Key: Project
          Value: !Ref ProjectName
        - Key: Environment
          Value: !Ref Environment
        - Key: CostCenter
          Value: !Ref CostCenter
        - Key: ManagedBy
          Value: "CloudFormation"
```

**หมายเหตุ:** Ansible จัดการ tags เพิ่มเติมผ่าน `tags` parameter ใน playbook

## 🔍 **Template Validation Checklist**

### **✅ Basic Structure**
- [ ] AWSTemplateFormatVersion present
- [ ] Description includes service name and version
- [ ] Metadata section with version info
- [ ] AWS::CloudFormation::Interface with parameter groups

### **✅ Parameters Validation**
- [ ] ProjectName parameter exists
- [ ] Environment parameter with correct AllowedValues
- [ ] UniqueStackName parameter with appropriate default
- [ ] CostCenter parameter with default "IT"
- [ ] ResourceDeletionPolicy parameter with ["Delete", "Retain", "Snapshot"]
- [ ] ResourceUpdateReplacePolicy parameter with ["Delete", "Retain", "Snapshot"]

### **✅ Parameter Descriptions (Rule 8)**
- [ ] All parameters have update behavior documentation
- [ ] Description format: "Description (Update requires: [BEHAVIOR])"
- [ ] Correct behavior categories used (No interruption/Some interruption/Replacement)

### **✅ Policy Parameters (Rule 9)**
- [ ] ResourceDeletionPolicy parameter exists with default "Delete"
- [ ] ResourceUpdateReplacePolicy parameter exists with default "Delete"
- [ ] Required conditions exist (ShouldRetainOnDelete, ShouldRetainOnReplace, etc.)
- [ ] Resources use conditional policies based on capability matrix

### **✅ Import Mode Validation (for Infrastructure & Service Stacks)**
- [ ] VPCImportMode parameter with ["AUTO", "MANUAL"] values (for VPC using EIP)
- [ ] EIPImportMode parameter with ["AUTO", "MANUAL"] values (for VPC templates)
- [ ] VPCImportMode default is "AUTO"
- [ ] VPCStackUniqueName parameter exists (for service stacks)
- [ ] Manual mode parameters (VpcId, SubnetIds, EIPAllocationIds) with empty defaults
- [ ] UseManualVPC/UseManualEIP condition exists
- [ ] Resources use !If conditions for imports

### **✅ Target Group Validation (Rule 10)**
- [ ] Target Group names include port: "${UniqueStackName}-tg-${ContainerPort}"
- [ ] Target Groups have UpdateReplacePolicy: Retain (always)
- [ ] Target Groups use parameter-driven DeletionPolicy
- [ ] NLB Target Groups have DependsOn: NetworkLoadBalancer

### **✅ Tagging Validation**
- [ ] CostCenter parameter exists with default "IT"
- [ ] Resources use !Ref for tag values (Project, Environment, CostCenter)
- [ ] ManagedBy tag set to "CloudFormation"
- [ ] No hardcoded tag values

### **✅ Resources Validation**
- [ ] All resources use conditional imports where applicable
- [ ] Security Groups reference VPC conditionally
- [ ] Subnets reference conditionally
- [ ] Resources use policy parameters correctly based on capability matrix
- [ ] Snapshot policies only used with ElastiCache (if applicable)

### **✅ Outputs Validation**
- [ ] All major resources have outputs
- [ ] **StackName output added (บังคับใหม่)**
- [ ] Export names follow naming convention
- [ ] Export names use !Sub with standard pattern
- [ ] Cross-stack references use Export Stack Parameters
- [ ] Descriptions are clear and consistent

### **✅ Dependencies Validation**
- [ ] Foundation stacks have no Import dependencies
- [ ] Dependent stacks properly reference foundation stacks
- [ ] No circular dependencies
- [ ] Import/Export chain is logical
- [ ] DependsOn used where necessary (Routes, Target Groups, etc.)

## 🚨 **Common Violations**

### **❌ Missing Standard Parameters**
```yaml
# Wrong - missing required parameters
Parameters:
  VpcCidr:
    Type: String
```

### **❌ Hardcoded Import Mode**
```yaml
# Wrong - no flexibility
Resources:
  MyResource:
    Properties:
      VpcId: !ImportValue "hardcoded-vpc-id"
```

### **❌ Incorrect Export Naming**
```yaml
# Wrong - doesn't follow convention
Export:
  Name: "MyVPC"  # Should be: !Sub '${ProjectName}-${Environment}-${UniqueStackName}-Id'
```

### **❌ Missing Conditions**
```yaml
# Wrong - no conditional logic for import modes
Resources:
  MyResource:
    Properties:
      VpcId: !Ref VpcId  # Should use !If condition
```

## 🛠️ **Validation Script**

```bash
#!/bin/bash
# validate-template.sh

TEMPLATE_FILE=$1

echo "🔍 Validating CloudFormation Template: $TEMPLATE_FILE"

# Check required parameters
echo "✅ Checking Standard Parameters..."
grep -q "ProjectName:" $TEMPLATE_FILE || echo "❌ Missing ProjectName parameter"
grep -q "Environment:" $TEMPLATE_FILE || echo "❌ Missing Environment parameter"
grep -q "UniqueStackName:" $TEMPLATE_FILE || echo "❌ Missing UniqueStackName parameter"
grep -q "CostCenter:" $TEMPLATE_FILE || echo "❌ Missing CostCenter parameter"

# Check import mode (for dependent stacks)
if grep -q "ImportValue\|VpcId" $TEMPLATE_FILE; then
    echo "✅ Checking Import Mode Support..."
    grep -q "VPCImportMode:" $TEMPLATE_FILE || echo "❌ Missing VPCImportMode parameter"
    grep -q "UseManualVPC:" $TEMPLATE_FILE || echo "❌ Missing UseManualVPC condition"
fi

# Check export naming
echo "✅ Checking Export Naming..."
if grep -q "Export:" $TEMPLATE_FILE; then
    grep -q "\${ProjectName}-\${Environment}-\${UniqueStackName}" $TEMPLATE_FILE || echo "❌ Export names don't follow convention"
fi

echo "✅ Validation completed"
```

## 📊 **Template Compliance Matrix**

| Template | Standard Params | Import Mode | Exports | Version | Status |
|----------|----------------|-------------|---------|---------|--------|
| eip-v1.0.yaml | ✅ | N/A | ✅ | ✅ | ✅ |
| vpc-v1.0.yaml | ✅ | ✅ (EIP) | ✅ | ✅ | ✅ |
| vpc-pnat-v1.0.yaml | ✅ | ✅ (EIP) | ✅ | ✅ | ✅ |
| alb-v1.0.yaml | ✅ | ✅ (VPC) | ✅ | ✅ | ✅ |
| ecs-cluster-v1.0.yaml | ✅ | ✅ (VPC) | ✅ | ✅ | ✅ |
| ecs-service-*-v1.0.yaml | ✅ | ✅ (VPC) | ✅ | ✅ | ✅ |

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Active Standard  
**Compliance**: Mandatory for all CloudFormation templates
