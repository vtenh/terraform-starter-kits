data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "non_www" {
  zone_id = data.aws_route53_zone.main.zone_id

  name = ""
  type = "A"

  alias {
    name                   = var.lb_dns_name
    zone_id                = var.lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = var.lb_dns_name
    zone_id                = var.lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "sendgrid" {
  count   = length(var.sendgrid_settings)
  zone_id = data.aws_route53_zone.main.zone_id

  name    = var.sendgrid_settings[count.index].name
  type    = "CNAME"
  ttl     = "5"
  records = [var.sendgrid_settings[count.index].value]
}

resource "aws_route53_record" "asset_cdn" {
  count   = var.cdn.sub_domain == "" ? 0 : 1
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.cdn.sub_domain
  type    = "CNAME"
  ttl     = "5"
  records = [var.cdn.cloudfront_domain_name]
}

resource "aws_route53_record" "firebase_verification" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_acme-challenge"
  type    = "TXT"
  ttl     = "5"

  records = ["QyqohHHOMZGbKVeS_D_PTKDP8uo8lsijzxEwxa85KR0"]
}

# https://business.facebook.com/settings/owned-domains/649175642713187?business_id=235626258081882
resource "aws_route53_record" "txt_domain_verification" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "vtenh.com"
  type    = "TXT"
  ttl     = "5"

  records = [
    "google-site-verification=wnYgMaCTDE3nQBaGLAAaF-Icd8fZ_78-IizzuSnHZGA",
    "facebook-domain-verification=lblw55yg9rjb6fw83w6txvwjxicj6z"
  ]
}
