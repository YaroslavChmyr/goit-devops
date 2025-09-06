# EBS CSI Driver for EKS
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.28.0-eksbuild.1"

  depends_on = [aws_eks_node_group.main]
}
