# terraform/ec2_bastion.tf

# 1. Procura automática da versão mais recente do Amazon Linux 2023 (AMI)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Criação da Role do IAM (Permissão para a máquina se conectar via AWS Console)
resource "aws_iam_role" "bastion_role" {
  name = "jgs-framework-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 3. Anexar a política do SSM (Systems Manager) à Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4. Criar o Perfil da Instância (O "uniforme" que a máquina vai vestir)
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "jgs-framework-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# 5. A Máquina EC2 (Bastion Host)
resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  
  # A Governança da Rede: Anexamos o "Crachá" que tem acesso ao RDS
  vpc_security_group_ids = [aws_security_group.etl_sg.id]
  
  # A Governança de Acesso: Vestimos a máquina com o "Uniforme" do SSM
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name        = "jgs-bastion-host"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}