provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}
resource "azurerm_resource_group" "rg-kp-ks" {
    name     = ""
    location = "Poland Central"
}


data "azuread_user" "username_id" {
  user_principal_name = var.sql_admin_username
}

data "azuread_user" "second_username_id" {
  user_principal_name = var.sql_username
}

resource "azurerm_key_vault" "kv-kp-ks" {
  name                        = ""
  location                    = azurerm_resource_group.rg-kp-ks.location
  resource_group_name         = azurerm_resource_group.rg-kp-ks.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  purge_protection_enabled    = true

  dynamic "access_policy" {
      for_each = [data.azuread_user.username_id, data.azuread_user.second_username_id]
      content {
        tenant_id = var.tenant_id
        object_id = access_policy.value.object_id

        secret_permissions = [
          "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
        ]
      }
    }
  tags = var.default_tags

  depends_on = [azurerm_resource_group.rg-kp-ks]
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each            = var.key_vault_secrets
  name                = each.key
  value               = each.value
  key_vault_id        = azurerm_key_vault.kv-kp-ks.id
  content_type        = "text/plain"
  tags                = var.default_tags
  depends_on = [azurerm_key_vault.kv-kp-ks]
}


## Source SQL Server setup


resource "local_file" "create_user_sql" {
  filename = "${path.module}/scripts/create_user.sql"
  content  = <<EOT
  CREATE USER [${var.sql_username}] FROM EXTERNAL PROVIDER;
  ALTER ROLE db_owner ADD MEMBER [${var.sql_username}];
  EOT
}

resource "azurerm_mssql_server" "src_kp_ks_sql_server" {
    name                         = ""
    resource_group_name          = azurerm_resource_group.rg-kp-ks.name
    location                     = azurerm_resource_group.rg-kp-ks.location
    version                      = "12.0"
    azuread_administrator {
        login_username = data.azuread_user.username_id.user_principal_name
        tenant_id      = var.tenant_id
        object_id      = data.azuread_user.username_id.object_id
        azuread_authentication_only = true
    }

    tags = var.default_tags

    depends_on = [azurerm_resource_group.rg-kp-ks]
}

resource "azurerm_mssql_firewall_rule" "src_firewall_rules" {
    for_each = { for rule in var.firewall_rules : rule.name => rule }
    server_id = azurerm_mssql_server.src_kp_ks_sql_server.id
    name                = each.value.name
    start_ip_address    = each.value.start_ip_address
    end_ip_address      = each.value.end_ip_address
}

resource "azurerm_mssql_database" "src_kp_ks_sqldb" {
    name                = "SRC_DB"
    server_id           = azurerm_mssql_server.src_kp_ks_sql_server.id
    sku_name            = "GP_S_Gen5_1"
    storage_account_type = "Local"
    zone_redundant = false
    auto_pause_delay_in_minutes = 60
    min_capacity = 0.5
    
    tags = var.default_tags

    depends_on = [azurerm_mssql_server.src_kp_ks_sql_server]
}

# custom script execution

resource "null_resource" "src_create_sql_user" {
  depends_on = [azurerm_mssql_database.src_kp_ks_sqldb,  local_file.create_user_sql]

  provisioner "local-exec" {
    command = "sqlcmd -S tcp:${azurerm_mssql_server.src_kp_ks_sql_server.fully_qualified_domain_name},1433 -G -d ${azurerm_mssql_database.src_kp_ks_sqldb.name} -i scripts/create_user.sql"
  }
 triggers = {always_run = "${timestamp()}"}
}

resource "null_resource" "src_sql_init_script" {
  depends_on = [azurerm_mssql_database.src_kp_ks_sqldb,  local_file.create_user_sql]

  provisioner "local-exec" {
    command = "sqlcmd -S tcp:${azurerm_mssql_server.src_kp_ks_sql_server.fully_qualified_domain_name},1433 -G -d ${azurerm_mssql_database.src_kp_ks_sqldb.name} -i scripts/db_init.sql"
  }
 triggers = {always_run = "${timestamp()}"}
}



## Target SQL Server setup


resource "azurerm_mssql_server" "trg_kp_ks_sql_server" {
    name                         = ""
    resource_group_name          = azurerm_resource_group.rg-kp-ks.name
    location                     = azurerm_resource_group.rg-kp-ks.location
    version                      = "12.0"
    azuread_administrator {
        login_username = data.azuread_user.username_id.user_principal_name
        tenant_id      = var.tenant_id
        object_id      = data.azuread_user.username_id.object_id
        azuread_authentication_only = true
    }

    tags = var.default_tags

    depends_on = [azurerm_resource_group.rg-kp-ks]
}

resource "azurerm_mssql_firewall_rule" "trg_firewall_rules" {
    for_each = { for rule in var.firewall_rules : rule.name => rule }
    server_id = azurerm_mssql_server.trg_kp_ks_sql_server.id
    name                = each.value.name
    start_ip_address    = each.value.start_ip_address
    end_ip_address      = each.value.end_ip_address
}

resource "azurerm_mssql_database" "trg_kp_ks_sqldb" {
    name                = "TRG_DB"
    server_id           = azurerm_mssql_server.trg_kp_ks_sql_server.id
    sku_name            = "GP_S_Gen5_1"
    storage_account_type = "Local"
    zone_redundant = false
    auto_pause_delay_in_minutes = 60
    min_capacity = 0.5
    
    tags = var.default_tags

    depends_on = [azurerm_mssql_server.trg_kp_ks_sql_server]
}

# custom script execution

resource "null_resource" "trg_create_sql_user" {
 provisioner "local-exec" {
    command = "sqlcmd -S tcp:${azurerm_mssql_server.trg_kp_ks_sql_server.fully_qualified_domain_name},1433 -G -d ${azurerm_mssql_database.trg_kp_ks_sqldb.name} -i scripts/create_user.sql"
  }
  depends_on = [azurerm_mssql_database.trg_kp_ks_sqldb, local_file.create_user_sql]
  triggers = {always_run = "${timestamp()}"}
}

resource "time_sleep" "wait_for_sql_operations" {
  depends_on = [null_resource.src_create_sql_user, null_resource.trg_create_sql_user]
  create_duration = "30s"
}

resource "null_resource" "delete_local_file" {
  provisioner "local-exec" {
    command = "del /q scripts\\create_user.sql"
  }
  depends_on = [time_sleep.wait_for_sql_operations]
  triggers = {always_run = "${timestamp()}"}
}

