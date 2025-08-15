variable "group_num" {
  type = string
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "tags" {
  type    = map(string)
  default = {} # or set a basic map here
}
