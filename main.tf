resource "aws_acm_certificate" "marti_cert" {
  domain_name = "*.martinhristov.xyz"
  validation_method = "DNS"
  subject_alternative_names = ["martinhristov.xyz"]
  
  options {
      # Enables putting SCT in the certificate.
      certificate_transparency_logging_preference = "ENABLED"
  }
  # Recommended by Terraform
  lifecycle {
      create_before_destroy = true
  }
}

data "aws_route53_zone" "marti_zone"{
    name = "martinhristov.xyz."
    private_zone = false
}
# Resource indices probably needed
resource "aws_route53_record" "verification_record" {
  name = aws_acm_certificate.marti_cert.domain_validation_options.0.resource_record_name
  type = aws_acm_certificate.marti_cert.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.marti_zone.id
  records = [aws_acm_certificate.marti_cert.domain_validation_options.0.resource_record_value]
  ttl  = 300
}
# Actual verification of the cert
resource "aws_acm_certificate_validation" "validate_cert" {
  certificate_arn = aws_acm_certificate.marti_cert.arn
  validation_record_fqdns = [aws_route53_record.verification_record.fqdn]
}
# Using TF Cloud for runs and backend
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "tyloo"

    workspaces {
      name = "aws_cert_ct"
    }
  }
}
