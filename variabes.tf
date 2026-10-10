variable "vpc_id" {
  description = "EKS가 설치된 VPC ID"
  type        = string
  default     = "vpc-003002198deba19a3" # 실제 VPC ID 입력
}

variable "private_subnet_ids" {
  description = "TGW 인터페이스가 생성될 서브넷 리스트"
  type        = list(string)
  default     = ["subnet-07206907ba6beaf2c", "subnet-008892edaa7c585b3"] # 실제 서브넷 입력
}

variable "vyos_public_ip" {
  description = "외부 IP"
  type        = string
  default     = "112.168.168.8"
}
