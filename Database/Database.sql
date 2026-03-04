/* =========================================================
   ERP (Printing Packaging) - SQL Server Schema from UC01..UC13
   Idempotent script: run many times without errors
   ========================================================= */

------------------------------------------------------------
-- 0) DATABASE
------------------------------------------------------------
IF DB_ID(N'erp_uc') IS NULL
BEGIN
    CREATE DATABASE erp_uc;
END
GO

USE erp_uc;
GO

------------------------------------------------------------
-- A) DROP TRIGGERS / ROUTINES FIRST
------------------------------------------------------------
IF OBJECT_ID(N'dbo.trg_users_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_users_updated_at;
IF OBJECT_ID(N'dbo.trg_customers_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_customers_updated_at;
IF OBJECT_ID(N'dbo.trg_suppliers_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_suppliers_updated_at;
IF OBJECT_ID(N'dbo.trg_items_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_items_updated_at;
IF OBJECT_ID(N'dbo.trg_quotations_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_quotations_updated_at;
IF OBJECT_ID(N'dbo.trg_production_orders_updated_at', N'TR') IS NOT NULL DROP TRIGGER dbo.trg_production_orders_updated_at;
GO

IF OBJECT_ID(N'dbo.sp_post_inventory_doc', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_post_inventory_doc;
IF OBJECT_ID(N'dbo.sp_unpost_inventory_doc', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_unpost_inventory_doc;
IF OBJECT_ID(N'dbo.sp_post_receipt', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_post_receipt;
IF OBJECT_ID(N'dbo.sp_unpost_receipt', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_unpost_receipt;
GO

IF OBJECT_ID(N'dbo.fn_get_acc', N'FN') IS NOT NULL DROP FUNCTION dbo.fn_get_acc;
GO

------------------------------------------------------------
-- B) DROP TABLES (ORDERED)
------------------------------------------------------------
IF OBJECT_ID(N'dbo.journal_lines', N'U') IS NOT NULL DROP TABLE dbo.journal_lines;
IF OBJECT_ID(N'dbo.journal_entries', N'U') IS NOT NULL DROP TABLE dbo.journal_entries;

IF OBJECT_ID(N'dbo.stock_movements', N'U') IS NOT NULL DROP TABLE dbo.stock_movements;

IF OBJECT_ID(N'dbo.receipt_apply', N'U') IS NOT NULL DROP TABLE dbo.receipt_apply;
IF OBJECT_ID(N'dbo.cash_receipts', N'U') IS NOT NULL DROP TABLE dbo.cash_receipts;

IF OBJECT_ID(N'dbo.sales_invoice_lines', N'U') IS NOT NULL DROP TABLE dbo.sales_invoice_lines;
IF OBJECT_ID(N'dbo.sales_invoices', N'U') IS NOT NULL DROP TABLE dbo.sales_invoices;

IF OBJECT_ID(N'dbo.inventory_lines', N'U') IS NOT NULL DROP TABLE dbo.inventory_lines;
IF OBJECT_ID(N'dbo.inventory_docs', N'U') IS NOT NULL DROP TABLE dbo.inventory_docs;

IF OBJECT_ID(N'dbo.production_bom_lines', N'U') IS NOT NULL DROP TABLE dbo.production_bom_lines;
IF OBJECT_ID(N'dbo.production_orders', N'U') IS NOT NULL DROP TABLE dbo.production_orders;

IF OBJECT_ID(N'dbo.quotation_costs', N'U') IS NOT NULL DROP TABLE dbo.quotation_costs;
IF OBJECT_ID(N'dbo.quotation_lines', N'U') IS NOT NULL DROP TABLE dbo.quotation_lines;
IF OBJECT_ID(N'dbo.quotation_approvals', N'U') IS NOT NULL DROP TABLE dbo.quotation_approvals;
IF OBJECT_ID(N'dbo.quotations', N'U') IS NOT NULL DROP TABLE dbo.quotations;

IF OBJECT_ID(N'dbo.items', N'U') IS NOT NULL DROP TABLE dbo.items;
IF OBJECT_ID(N'dbo.suppliers', N'U') IS NOT NULL DROP TABLE dbo.suppliers;
IF OBJECT_ID(N'dbo.customers', N'U') IS NOT NULL DROP TABLE dbo.customers;

IF OBJECT_ID(N'dbo.sys_account_defaults', N'U') IS NOT NULL DROP TABLE dbo.sys_account_defaults;
IF OBJECT_ID(N'dbo.accounts', N'U') IS NOT NULL DROP TABLE dbo.accounts;

IF OBJECT_ID(N'dbo.audit_logs', N'U') IS NOT NULL DROP TABLE dbo.audit_logs;
IF OBJECT_ID(N'dbo.login_logs', N'U') IS NOT NULL DROP TABLE dbo.login_logs;

IF OBJECT_ID(N'dbo.[users]', N'U') IS NOT NULL DROP TABLE dbo.[users];
IF OBJECT_ID(N'dbo.roles', N'U') IS NOT NULL DROP TABLE dbo.roles;

IF OBJECT_ID(N'dbo.warehouses', N'U') IS NOT NULL DROP TABLE dbo.warehouses;
GO

------------------------------------------------------------
-- 1) ROLE + USER + LOGIN LOG (UC01)
------------------------------------------------------------
CREATE TABLE dbo.roles (
  role_id   INT NOT NULL PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.[users] (
  user_id     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  full_name   VARCHAR(120) NOT NULL,
  email       VARCHAR(120) NOT NULL UNIQUE,
  [password]  VARCHAR(200) NOT NULL,
  role_id     INT NOT NULL,
  is_active   TINYINT NOT NULL CONSTRAINT DF_users_is_active DEFAULT (1),
  created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_users_created_at DEFAULT (SYSDATETIME()),
  updated_at  DATETIME2(0) NULL,
  CONSTRAINT FK_users_roles FOREIGN KEY (role_id) REFERENCES dbo.roles(role_id)
);
GO

CREATE TABLE dbo.login_logs (
  login_log_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  email        VARCHAR(120) NOT NULL,
  user_id      INT NULL,
  success      TINYINT NOT NULL,
  ip_address   VARCHAR(45) NULL,
  user_agent   VARCHAR(255) NULL,
  created_at   DATETIME2(0) NOT NULL CONSTRAINT DF_login_logs_created_at DEFAULT (SYSDATETIME()),
  CONSTRAINT FK_login_logs_users FOREIGN KEY (user_id) REFERENCES dbo.[users](user_id)
);
GO

CREATE INDEX idx_login_logs_email_created ON dbo.login_logs(email, created_at);
GO

CREATE TABLE dbo.audit_logs (
  audit_id     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  user_id      INT NULL,
  action       VARCHAR(50) NOT NULL,
  object_type  VARCHAR(50) NOT NULL,
  object_id    BIGINT NULL,
  note         VARCHAR(255) NULL,
  created_at   DATETIME2(0) NOT NULL CONSTRAINT DF_audit_logs_created_at DEFAULT (SYSDATETIME()),
  CONSTRAINT FK_audit_logs_users FOREIGN KEY (user_id) REFERENCES dbo.[users](user_id)
);
GO

CREATE INDEX idx_audit_object ON dbo.audit_logs(object_type, object_id);
GO

------------------------------------------------------------
-- 2) KHO (warehouse)
------------------------------------------------------------
CREATE TABLE dbo.warehouses (
  warehouse_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  wh_code      VARCHAR(30) NOT NULL UNIQUE,
  wh_name      VARCHAR(120) NOT NULL
);
GO

------------------------------------------------------------
-- 3) ACCOUNTS + DEFAULT MAP (for posting)
------------------------------------------------------------
CREATE TABLE dbo.accounts (
  account_code VARCHAR(30) NOT NULL PRIMARY KEY,
  account_name VARCHAR(150) NOT NULL,
  acc_type     NVARCHAR(30) NOT NULL,
  CONSTRAINT CK_accounts_acc_type CHECK (acc_type IN
    (N'TÀI SẢN', N'NỢ PHẢI TRẢ', N'VỐN CHỦ SỞ HỮU', N'DOANH THU', N'CHI PHÍ'))
);
GO

CREATE TABLE dbo.sys_account_defaults (
  key_name      VARCHAR(50) NOT NULL PRIMARY KEY,
  account_code  VARCHAR(30) NOT NULL,
  CONSTRAINT FK_sys_account_defaults_accounts
    FOREIGN KEY (account_code) REFERENCES dbo.accounts(account_code)
);
GO

------------------------------------------------------------
-- 4) MASTER DATA (UC02-UC04)
------------------------------------------------------------
CREATE TABLE dbo.customers (
  customer_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  customer_code  VARCHAR(30) NOT NULL UNIQUE,
  customer_name  VARCHAR(150) NOT NULL,
  address        VARCHAR(255) NULL,
  tax_code       VARCHAR(30) NULL,
  phone          VARCHAR(30) NULL,
  email          VARCHAR(120) NULL,
  is_active      TINYINT NOT NULL CONSTRAINT DF_customers_is_active DEFAULT (1),
  created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_customers_created_at DEFAULT (SYSDATETIME()),
  updated_at     DATETIME2(0) NULL
);
GO

CREATE TABLE dbo.suppliers (
  supplier_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  supplier_code  VARCHAR(30) NOT NULL UNIQUE,
  supplier_name  VARCHAR(150) NOT NULL,
  address        VARCHAR(255) NULL,
  tax_code       VARCHAR(30) NULL,
  phone          VARCHAR(30) NULL,
  email          VARCHAR(120) NULL,
  is_active      TINYINT NOT NULL CONSTRAINT DF_suppliers_is_active DEFAULT (1),
  created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_suppliers_created_at DEFAULT (SYSDATETIME()),
  updated_at     DATETIME2(0) NULL
);
GO

CREATE TABLE dbo.items (
  item_id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  item_code            VARCHAR(40) NOT NULL UNIQUE,
  item_name            VARCHAR(180) NOT NULL,
  uom                  VARCHAR(20) NOT NULL,
  item_type            VARCHAR(10) NOT NULL,
  default_cost         DECIMAL(18,2) NOT NULL CONSTRAINT DF_items_default_cost DEFAULT (0),
  is_active            TINYINT NOT NULL CONSTRAINT DF_items_is_active DEFAULT (1),
  inv_account_code     VARCHAR(30) NULL,
  revenue_account_code VARCHAR(30) NULL,
  expense_account_code VARCHAR(30) NULL,
  created_at           DATETIME2(0) NOT NULL CONSTRAINT DF_items_created_at DEFAULT (SYSDATETIME()),
  updated_at           DATETIME2(0) NULL,
  CONSTRAINT CK_items_item_type CHECK (item_type IN ('NVL','HH','TP')),
  CONSTRAINT FK_items_inv_acc FOREIGN KEY (inv_account_code) REFERENCES dbo.accounts(account_code),
  CONSTRAINT FK_items_rev_acc FOREIGN KEY (revenue_account_code) REFERENCES dbo.accounts(account_code),
  CONSTRAINT FK_items_exp_acc FOREIGN KEY (expense_account_code) REFERENCES dbo.accounts(account_code)
);
GO

------------------------------------------------------------
-- 5) QUOTATION (UC05, UC06)
------------------------------------------------------------
CREATE TABLE dbo.quotations (
  quote_id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  quote_no        VARCHAR(40) NOT NULL UNIQUE,
  quote_date      DATE NOT NULL,
  customer_id     INT NOT NULL,
  status          VARCHAR(20) NOT NULL CONSTRAINT DF_quotations_status DEFAULT ('NHAP'),
  profit_percent  DECIMAL(6,2) NOT NULL CONSTRAINT DF_quotations_profit DEFAULT (0),
  total_cost      DECIMAL(18,2) NOT NULL CONSTRAINT DF_quotations_total_cost DEFAULT (0),
  total_price     DECIMAL(18,2) NOT NULL CONSTRAINT DF_quotations_total_price DEFAULT (0),
  created_by      INT NOT NULL,
  created_at      DATETIME2(0) NOT NULL CONSTRAINT DF_quotations_created_at DEFAULT (SYSDATETIME()),
  updated_at      DATETIME2(0) NULL,
  CONSTRAINT CK_quotations_status CHECK (status IN ('NHAP','CHO_DUYET','DA_DUYET','TU_CHOI')),
  CONSTRAINT FK_quotations_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
  CONSTRAINT FK_quotations_users FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id)
);
GO

CREATE TABLE dbo.quotation_lines (
  quote_line_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  quote_id      BIGINT NOT NULL,
  item_id       INT NOT NULL,
  qty           DECIMAL(18,3) NOT NULL CONSTRAINT DF_quotation_lines_qty DEFAULT (0),
  spec          VARCHAR(255) NULL,
  line_cost     DECIMAL(18,2) NOT NULL CONSTRAINT DF_quotation_lines_cost DEFAULT (0),
  line_price    DECIMAL(18,2) NOT NULL CONSTRAINT DF_quotation_lines_price DEFAULT (0),
  CONSTRAINT FK_ql_quote FOREIGN KEY (quote_id) REFERENCES dbo.quotations(quote_id) ON DELETE CASCADE,
  CONSTRAINT FK_ql_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id)
);
GO
CREATE INDEX idx_quote_lines_quote ON dbo.quotation_lines(quote_id);
GO

CREATE TABLE dbo.quotation_costs (
  cost_id     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  quote_id    BIGINT NOT NULL,
  cost_name   VARCHAR(120) NOT NULL,
  cost_amount DECIMAL(18,2) NOT NULL CONSTRAINT DF_quotation_costs_amount DEFAULT (0),
  note        VARCHAR(255) NULL,
  CONSTRAINT FK_qc_quote FOREIGN KEY (quote_id) REFERENCES dbo.quotations(quote_id) ON DELETE CASCADE
);
GO
CREATE INDEX idx_quote_costs_quote ON dbo.quotation_costs(quote_id);
GO

CREATE TABLE dbo.quotation_approvals (
  approval_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  quote_id     BIGINT NOT NULL,
  approved_by  INT NOT NULL,
  approved_at  DATETIME2(0) NOT NULL CONSTRAINT DF_quotation_approvals_at DEFAULT (SYSDATETIME()),
  decision     VARCHAR(20) NOT NULL,
  note         VARCHAR(255) NULL,
  CONSTRAINT CK_quotation_approvals_decision CHECK (decision IN ('DA_DUYET','TU_CHOI')),
  CONSTRAINT FK_qa_quote FOREIGN KEY (quote_id) REFERENCES dbo.quotations(quote_id) ON DELETE CASCADE,
  CONSTRAINT FK_qa_user FOREIGN KEY (approved_by) REFERENCES dbo.[users](user_id)
);
GO
CREATE INDEX idx_quote_approval_quote ON dbo.quotation_approvals(quote_id);
GO

------------------------------------------------------------
-- 6) PRODUCTION (UC07, UC08)
------------------------------------------------------------
CREATE TABLE dbo.production_orders (
  prod_id     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  prod_no     VARCHAR(40) NOT NULL UNIQUE,
  quote_id    BIGINT NOT NULL,
  status      VARCHAR(30) NOT NULL CONSTRAINT DF_production_orders_status DEFAULT ('CHUA_THUC_HIEN'),
  start_date  DATE NULL,
  due_date    DATE NULL,
  note        VARCHAR(255) NULL,
  created_by  INT NOT NULL,
  created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_production_orders_created_at DEFAULT (SYSDATETIME()),
  updated_at  DATETIME2(0) NULL,
  CONSTRAINT CK_production_orders_status CHECK (status IN ('CHUA_THUC_HIEN','DANG_SAN_XUAT','HOAN_THANH')),
  CONSTRAINT FK_po_quote FOREIGN KEY (quote_id) REFERENCES dbo.quotations(quote_id),
  CONSTRAINT FK_po_user  FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id)
);
GO

CREATE TABLE dbo.production_bom_lines (
  bom_line_id       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  prod_id           BIGINT NOT NULL,
  material_item_id  INT NOT NULL,
  qty_norm          DECIMAL(18,3) NOT NULL CONSTRAINT DF_bom_qty DEFAULT (0),
  note              VARCHAR(255) NULL,
  CONSTRAINT FK_bom_prod FOREIGN KEY (prod_id) REFERENCES dbo.production_orders(prod_id) ON DELETE CASCADE,
  CONSTRAINT FK_bom_item FOREIGN KEY (material_item_id) REFERENCES dbo.items(item_id)
);
GO
CREATE INDEX idx_bom_prod ON dbo.production_bom_lines(prod_id);
GO

------------------------------------------------------------
-- 7) INVENTORY (UC09, UC10, UC11)
------------------------------------------------------------
CREATE TABLE dbo.inventory_docs (
  inv_id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  inv_no        VARCHAR(40) NOT NULL UNIQUE,
  inv_date      DATE NOT NULL,
  doc_type      VARCHAR(30) NOT NULL,
  warehouse_id  INT NOT NULL,
  prod_id       BIGINT NULL,
  supplier_id   INT NULL,
  status        VARCHAR(20) NOT NULL CONSTRAINT DF_inventory_docs_status DEFAULT ('NHAP'),
  note          VARCHAR(255) NULL,
  created_by    INT NOT NULL,
  created_at    DATETIME2(0) NOT NULL CONSTRAINT DF_inventory_docs_created_at DEFAULT (SYSDATETIME()),
  posted_by     INT NULL,
  posted_at     DATETIME2(0) NULL,
  CONSTRAINT CK_inventory_docs_doc_type CHECK (doc_type IN
    ('XUAT_NVL_SX','NHAP_TP_SX','NHAP_TU_MUA','NHAP_DIEU_CHINH','XUAT_DIEU_CHINH')),
  CONSTRAINT CK_inventory_docs_status CHECK (status IN ('NHAP','DA_GHI_SO')),
  CONSTRAINT FK_inv_wh FOREIGN KEY (warehouse_id) REFERENCES dbo.warehouses(warehouse_id),
  CONSTRAINT FK_inv_prod FOREIGN KEY (prod_id) REFERENCES dbo.production_orders(prod_id),
  CONSTRAINT FK_inv_supplier FOREIGN KEY (supplier_id) REFERENCES dbo.suppliers(supplier_id),
  CONSTRAINT FK_inv_created_by FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id),
  CONSTRAINT FK_inv_posted_by FOREIGN KEY (posted_by) REFERENCES dbo.[users](user_id)
);
GO

CREATE INDEX idx_inv_status_date ON dbo.inventory_docs(status, inv_date);
CREATE INDEX idx_inv_prod ON dbo.inventory_docs(prod_id);
CREATE INDEX idx_inv_supplier ON dbo.inventory_docs(supplier_id);
GO

CREATE TABLE dbo.inventory_lines (
  inv_line_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  inv_id      BIGINT NOT NULL,
  item_id     INT NOT NULL,
  qty         DECIMAL(18,3) NOT NULL CONSTRAINT DF_inventory_lines_qty DEFAULT (0),
  unit_cost   DECIMAL(18,2) NOT NULL CONSTRAINT DF_inventory_lines_unit_cost DEFAULT (0),
  amount      DECIMAL(18,2) NOT NULL CONSTRAINT DF_inventory_lines_amount DEFAULT (0),
  CONSTRAINT FK_inv_lines_doc FOREIGN KEY (inv_id) REFERENCES dbo.inventory_docs(inv_id) ON DELETE CASCADE,
  CONSTRAINT FK_inv_lines_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id)
);
GO
CREATE INDEX idx_inv_lines_inv ON dbo.inventory_lines(inv_id);
CREATE INDEX idx_inv_lines_item ON dbo.inventory_lines(item_id);
GO

CREATE TABLE dbo.stock_movements (
  move_id      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  inv_id       BIGINT NOT NULL,
  inv_line_id  BIGINT NOT NULL,
  warehouse_id INT NOT NULL,
  item_id      INT NOT NULL,
  move_date    DATE NOT NULL,
  qty_in       DECIMAL(18,3) NOT NULL CONSTRAINT DF_sm_qty_in DEFAULT (0),
  qty_out      DECIMAL(18,3) NOT NULL CONSTRAINT DF_sm_qty_out DEFAULT (0),
  unit_cost    DECIMAL(18,2) NOT NULL CONSTRAINT DF_sm_unit_cost DEFAULT (0),
  amount       DECIMAL(18,2) NOT NULL CONSTRAINT DF_sm_amount DEFAULT (0),
  CONSTRAINT FK_sm_inv FOREIGN KEY (inv_id) REFERENCES dbo.inventory_docs(inv_id) ON DELETE CASCADE,
  CONSTRAINT FK_sm_line FOREIGN KEY (inv_line_id) REFERENCES dbo.inventory_lines(inv_line_id) ON DELETE CASCADE,
  CONSTRAINT FK_sm_wh FOREIGN KEY (warehouse_id) REFERENCES dbo.warehouses(warehouse_id),
  CONSTRAINT FK_sm_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id)
);
GO
CREATE INDEX idx_sm_item_wh_date ON dbo.stock_movements(item_id, warehouse_id, move_date);
CREATE INDEX idx_sm_inv ON dbo.stock_movements(inv_id);
GO

------------------------------------------------------------
-- 8) SALES INVOICE + RECEIPT (UC12)
------------------------------------------------------------
CREATE TABLE dbo.sales_invoices (
  invoice_id    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  invoice_no    VARCHAR(40) NOT NULL UNIQUE,
  invoice_date  DATE NOT NULL,
  customer_id   INT NOT NULL,
  total_amount  DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_invoices_total DEFAULT (0),
  paid_amount   DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_invoices_paid DEFAULT (0),
  status        VARCHAR(20) NOT NULL CONSTRAINT DF_sales_invoices_status DEFAULT ('CHUA_THU'),
  created_by    INT NULL,
  created_at    DATETIME2(0) NOT NULL CONSTRAINT DF_sales_invoices_created_at DEFAULT (SYSDATETIME()),
  CONSTRAINT CK_sales_invoices_status CHECK (status IN ('CHUA_THU','THU_MOT_PHAN','DA_THU')),
  CONSTRAINT FK_si_customer FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
  CONSTRAINT FK_si_user FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id)
);
GO

CREATE TABLE dbo.sales_invoice_lines (
  invoice_line_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  invoice_id      BIGINT NOT NULL,
  item_id         INT NOT NULL,
  qty             DECIMAL(18,3) NOT NULL CONSTRAINT DF_sil_qty DEFAULT (0),
  unit_price      DECIMAL(18,2) NOT NULL CONSTRAINT DF_sil_unit_price DEFAULT (0),
  amount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_sil_amount DEFAULT (0),
  CONSTRAINT FK_sil_invoice FOREIGN KEY (invoice_id) REFERENCES dbo.sales_invoices(invoice_id) ON DELETE CASCADE,
  CONSTRAINT FK_sil_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id)
);
GO
CREATE INDEX idx_sil_invoice ON dbo.sales_invoice_lines(invoice_id);
GO

CREATE TABLE dbo.cash_receipts (
  receipt_id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  receipt_no        VARCHAR(40) NOT NULL UNIQUE,
  receipt_date      DATE NOT NULL,
  customer_id       INT NOT NULL,
  method            VARCHAR(50) NULL,
  cash_account_code VARCHAR(30) NULL,
  total_received    DECIMAL(18,2) NOT NULL CONSTRAINT DF_cash_receipts_total DEFAULT (0),
  status            VARCHAR(20) NOT NULL CONSTRAINT DF_cash_receipts_status DEFAULT ('NHAP'),
  note              VARCHAR(255) NULL,
  created_by        INT NOT NULL,
  created_at        DATETIME2(0) NOT NULL CONSTRAINT DF_cash_receipts_created_at DEFAULT (SYSDATETIME()),
  posted_by         INT NULL,
  posted_at         DATETIME2(0) NULL,
  CONSTRAINT CK_cash_receipts_status CHECK (status IN ('NHAP','DA_GHI_SO')),
  CONSTRAINT FK_cr_customer FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
  CONSTRAINT FK_cr_created_by FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id),
  CONSTRAINT FK_cr_posted_by FOREIGN KEY (posted_by) REFERENCES dbo.[users](user_id),
  CONSTRAINT FK_cr_cash_acc FOREIGN KEY (cash_account_code) REFERENCES dbo.accounts(account_code)
);
GO
CREATE INDEX idx_receipt_status_date ON dbo.cash_receipts(status, receipt_date);
GO

CREATE TABLE dbo.receipt_apply (
  apply_id       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  receipt_id     BIGINT NOT NULL,
  invoice_id     BIGINT NOT NULL,
  amount_applied DECIMAL(18,2) NOT NULL CONSTRAINT DF_receipt_apply_amount DEFAULT (0),
  CONSTRAINT FK_ra_receipt FOREIGN KEY (receipt_id) REFERENCES dbo.cash_receipts(receipt_id) ON DELETE CASCADE,
  CONSTRAINT FK_ra_invoice FOREIGN KEY (invoice_id) REFERENCES dbo.sales_invoices(invoice_id),
  CONSTRAINT UQ_receipt_invoice UNIQUE (receipt_id, invoice_id)
);
GO

------------------------------------------------------------
-- 9) JOURNAL (UC09/UC10/UC12/UC13)
------------------------------------------------------------
CREATE TABLE dbo.journal_entries (
  je_id          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  je_no          VARCHAR(40) NOT NULL UNIQUE,
  je_date        DATE NOT NULL,
  ref_type       VARCHAR(20) NOT NULL,
  ref_id         BIGINT NOT NULL,
  status         VARCHAR(20) NOT NULL CONSTRAINT DF_je_status DEFAULT ('POSTED'),
  created_by     INT NOT NULL,
  created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_je_created_at DEFAULT (SYSDATETIME()),
  reversed_by    INT NULL,
  reversed_at    DATETIME2(0) NULL,
  reversal_je_id BIGINT NULL,
  reverse_note   VARCHAR(255) NULL,
  CONSTRAINT CK_je_ref_type CHECK (ref_type IN ('INV_DOC','RECEIPT')),
  CONSTRAINT CK_je_status CHECK (status IN ('POSTED','REVERSED')),
  CONSTRAINT FK_je_created_by FOREIGN KEY (created_by) REFERENCES dbo.[users](user_id),
  CONSTRAINT FK_je_reversed_by FOREIGN KEY (reversed_by) REFERENCES dbo.[users](user_id)
);
GO
CREATE INDEX idx_je_ref ON dbo.journal_entries(ref_type, ref_id);
GO

CREATE TABLE dbo.journal_lines (
  jl_id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  je_id        BIGINT NOT NULL,
  account_code VARCHAR(30) NOT NULL,
  debit        DECIMAL(18,2) NOT NULL CONSTRAINT DF_jl_debit DEFAULT (0),
  credit       DECIMAL(18,2) NOT NULL CONSTRAINT DF_jl_credit DEFAULT (0),
  note         VARCHAR(255) NULL,
  CONSTRAINT FK_jl_je FOREIGN KEY (je_id) REFERENCES dbo.journal_entries(je_id) ON DELETE CASCADE,
  CONSTRAINT FK_jl_acc FOREIGN KEY (account_code) REFERENCES dbo.accounts(account_code)
);
GO
CREATE INDEX idx_jl_je ON dbo.journal_lines(je_id);
CREATE INDEX idx_jl_account ON dbo.journal_lines(account_code);
GO

------------------------------------------------------------
-- 10) TRIGGERS for updated_at (mimic ON UPDATE CURRENT_TIMESTAMP)
------------------------------------------------------------
CREATE TRIGGER dbo.trg_users_updated_at ON dbo.[users]
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE u SET updated_at = SYSDATETIME()
  FROM dbo.[users] u
  INNER JOIN inserted i ON i.user_id = u.user_id;
END
GO

CREATE TRIGGER dbo.trg_customers_updated_at ON dbo.customers
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE c SET updated_at = SYSDATETIME()
  FROM dbo.customers c
  INNER JOIN inserted i ON i.customer_id = c.customer_id;
END
GO

CREATE TRIGGER dbo.trg_suppliers_updated_at ON dbo.suppliers
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE s SET updated_at = SYSDATETIME()
  FROM dbo.suppliers s
  INNER JOIN inserted i ON i.supplier_id = s.supplier_id;
END
GO

CREATE TRIGGER dbo.trg_items_updated_at ON dbo.items
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE it SET updated_at = SYSDATETIME()
  FROM dbo.items it
  INNER JOIN inserted i ON i.item_id = it.item_id;
END
GO

CREATE TRIGGER dbo.trg_quotations_updated_at ON dbo.quotations
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE q SET updated_at = SYSDATETIME()
  FROM dbo.quotations q
  INNER JOIN inserted i ON i.quote_id = q.quote_id;
END
GO

CREATE TRIGGER dbo.trg_production_orders_updated_at ON dbo.production_orders
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE p SET updated_at = SYSDATETIME()
  FROM dbo.production_orders p
  INNER JOIN inserted i ON i.prod_id = p.prod_id;
END
GO

------------------------------------------------------------
-- 11) FUNCTION + PROCEDURES
------------------------------------------------------------
CREATE FUNCTION dbo.fn_get_acc (@p_key VARCHAR(50))
RETURNS VARCHAR(30)
AS
BEGIN
  DECLARE @v_acc VARCHAR(30);
  SELECT @v_acc = account_code
  FROM dbo.sys_account_defaults
  WHERE key_name = @p_key;
  RETURN @v_acc;
END
GO

CREATE PROCEDURE dbo.sp_post_inventory_doc
  @p_inv_id  BIGINT,
  @p_user_id INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @v_status   VARCHAR(20);
  DECLARE @v_doc_type VARCHAR(30);
  DECLARE @v_wh       INT;
  DECLARE @v_total    DECIMAL(18,2);

  DECLARE @v_acc_inv_nvl VARCHAR(30);
  DECLARE @v_acc_inv_tp  VARCHAR(30);
  DECLARE @v_acc_wip     VARCHAR(30);
  DECLARE @v_acc_ap      VARCHAR(30);
  DECLARE @v_acc_gain    VARCHAR(30);
  DECLARE @v_acc_loss    VARCHAR(30);

  DECLARE @v_je_id BIGINT;
  DECLARE @v_je_no VARCHAR(40);

  BEGIN TRY
    BEGIN TRAN;

    SELECT @v_status = status, @v_doc_type = doc_type, @v_wh = warehouse_id
    FROM dbo.inventory_docs WITH (UPDLOCK, ROWLOCK)
    WHERE inv_id = @p_inv_id;

    IF @v_status IS NULL
      THROW 50000, 'Inventory doc not found', 1;

    IF @v_status <> 'NHAP'
      THROW 50000, 'Only NHAP documents can be posted', 1;

    SELECT @v_total = ISNULL(SUM(amount), 0)
    FROM dbo.inventory_lines
    WHERE inv_id = @p_inv_id;

    SET @v_acc_inv_nvl = dbo.fn_get_acc('INV_NVL');
    SET @v_acc_inv_tp  = dbo.fn_get_acc('INV_TP');
    SET @v_acc_wip     = dbo.fn_get_acc('WIP');
    SET @v_acc_ap      = dbo.fn_get_acc('AP');
    SET @v_acc_gain    = dbo.fn_get_acc('INV_GAIN');
    SET @v_acc_loss    = dbo.fn_get_acc('INV_LOSS');

    SET @v_je_no = CONCAT('JE-', CONVERT(VARCHAR(8), GETDATE(), 112), '-', RIGHT('000000' + CAST(@p_inv_id AS VARCHAR(20)), 6));

    INSERT INTO dbo.journal_entries (je_no, je_date, ref_type, ref_id, status, created_by)
    VALUES (@v_je_no, CAST(GETDATE() AS DATE), 'INV_DOC', @p_inv_id, 'POSTED', @p_user_id);

    SET @v_je_id = CAST(SCOPE_IDENTITY() AS BIGINT);

    IF @v_doc_type = 'XUAT_NVL_SX'
    BEGIN
      INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
      VALUES
        (@v_je_id, @v_acc_wip,      @v_total, 0,       N'Xuất NVL cho sản xuất'),
        (@v_je_id, @v_acc_inv_nvl,  0,        @v_total, N'Giảm tồn NVL');
    END
    ELSE IF @v_doc_type = 'NHAP_TP_SX'
    BEGIN
      INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
      VALUES
        (@v_je_id, @v_acc_inv_tp, @v_total, 0,        N'Nhập thành phẩm từ SX'),
        (@v_je_id, @v_acc_wip,    0,        @v_total, N'Kết chuyển WIP');
    END
    ELSE IF @v_doc_type = 'NHAP_TU_MUA'
    BEGIN
      INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
      VALUES
        (@v_je_id, @v_acc_inv_nvl, @v_total, 0,        N'Nhập kho từ mua hàng'),
        (@v_je_id, @v_acc_ap,      0,        @v_total, N'Tăng công nợ NCC');
    END
    ELSE IF @v_doc_type = 'NHAP_DIEU_CHINH'
    BEGIN
      INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
      VALUES
        (@v_je_id, @v_acc_inv_nvl, @v_total, 0,        N'Tăng tồn điều chỉnh'),
        (@v_je_id, @v_acc_gain,    0,        @v_total, N'Chênh lệch tăng tồn');
    END
    ELSE IF @v_doc_type = 'XUAT_DIEU_CHINH'
    BEGIN
      INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
      VALUES
        (@v_je_id, @v_acc_loss,    @v_total, 0,        N'Chênh lệch giảm tồn'),
        (@v_je_id, @v_acc_inv_nvl, 0,        @v_total, N'Giảm tồn điều chỉnh');
    END
    ELSE
      THROW 50000, 'Unknown doc_type', 1;

    INSERT INTO dbo.stock_movements (inv_id, inv_line_id, warehouse_id, item_id, move_date, qty_in, qty_out, unit_cost, amount)
    SELECT
      l.inv_id,
      l.inv_line_id,
      @v_wh,
      l.item_id,
      d.inv_date,
      CASE WHEN @v_doc_type IN ('NHAP_TP_SX','NHAP_TU_MUA','NHAP_DIEU_CHINH') THEN l.qty ELSE 0 END,
      CASE WHEN @v_doc_type IN ('XUAT_NVL_SX','XUAT_DIEU_CHINH') THEN l.qty ELSE 0 END,
      l.unit_cost,
      l.amount
    FROM dbo.inventory_lines l
    INNER JOIN dbo.inventory_docs d ON d.inv_id = l.inv_id
    WHERE l.inv_id = @p_inv_id;

    UPDATE dbo.inventory_docs
    SET status = 'DA_GHI_SO', posted_by = @p_user_id, posted_at = SYSDATETIME()
    WHERE inv_id = @p_inv_id;

    INSERT INTO dbo.audit_logs (user_id, action, object_type, object_id, note)
    VALUES (@p_user_id, 'POST', 'INV_DOC', @p_inv_id, CONCAT('Posted inventory doc: ', @v_doc_type));

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

CREATE PROCEDURE dbo.sp_unpost_inventory_doc
  @p_inv_id  BIGINT,
  @p_user_id INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @v_status   VARCHAR(20);
  DECLARE @v_doc_type VARCHAR(30);
  DECLARE @v_je_id    BIGINT;
  DECLARE @v_rev_je_id BIGINT;
  DECLARE @v_rev_no   VARCHAR(60);

  BEGIN TRY
    BEGIN TRAN;

    SELECT @v_status = status, @v_doc_type = doc_type
    FROM dbo.inventory_docs WITH (UPDLOCK, ROWLOCK)
    WHERE inv_id = @p_inv_id;

    IF @v_status IS NULL
      THROW 50000, 'Inventory doc not found', 1;

    IF @v_status <> 'DA_GHI_SO'
      THROW 50000, 'Only DA_GHI_SO documents can be unposted', 1;

    SELECT TOP (1) @v_je_id = je_id
    FROM dbo.journal_entries WITH (UPDLOCK, ROWLOCK)
    WHERE ref_type = 'INV_DOC' AND ref_id = @p_inv_id AND status = 'POSTED'
    ORDER BY je_id DESC;

    IF @v_je_id IS NULL
      THROW 50000, 'Journal entry not found for this inventory doc', 1;

    SELECT @v_rev_no = CONCAT('REV-', je_no) FROM dbo.journal_entries WHERE je_id = @v_je_id;

    INSERT INTO dbo.journal_entries (je_no, je_date, ref_type, ref_id, status, created_by)
    VALUES (@v_rev_no, CAST(GETDATE() AS DATE), 'INV_DOC', @p_inv_id, 'POSTED', @p_user_id);

    SET @v_rev_je_id = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
    SELECT @v_rev_je_id, account_code, credit, debit, CONCAT('Reversal of JE#', @v_je_id)
    FROM dbo.journal_lines
    WHERE je_id = @v_je_id;

    UPDATE dbo.journal_entries
    SET status='REVERSED',
        reversed_by=@p_user_id,
        reversed_at=SYSDATETIME(),
        reversal_je_id=@v_rev_je_id,
        reverse_note='UNPOST inventory doc'
    WHERE je_id = @v_je_id;

    DELETE FROM dbo.stock_movements WHERE inv_id = @p_inv_id;

    UPDATE dbo.inventory_docs
    SET status='NHAP', posted_by=NULL, posted_at=NULL
    WHERE inv_id = @p_inv_id;

    INSERT INTO dbo.audit_logs (user_id, action, object_type, object_id, note)
    VALUES (@p_user_id, 'UNPOST', 'INV_DOC', @p_inv_id, CONCAT('Unposted inventory doc: ', @v_doc_type));

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

CREATE PROCEDURE dbo.sp_post_receipt
  @p_receipt_id BIGINT,
  @p_user_id    INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @v_status   VARCHAR(20);
  DECLARE @v_total    DECIMAL(18,2);
  DECLARE @v_cash_acc VARCHAR(30);
  DECLARE @v_ar_acc   VARCHAR(30);
  DECLARE @v_je_id    BIGINT;
  DECLARE @v_je_no    VARCHAR(50);

  BEGIN TRY
    BEGIN TRAN;

    SELECT @v_status = status, @v_total = total_received, @v_cash_acc = cash_account_code
    FROM dbo.cash_receipts WITH (UPDLOCK, ROWLOCK)
    WHERE receipt_id = @p_receipt_id;

    IF @v_status IS NULL
      THROW 50000, 'Receipt not found', 1;

    IF @v_status <> 'NHAP'
      THROW 50000, 'Only NHAP receipts can be posted', 1;

    IF @v_cash_acc IS NULL
      SET @v_cash_acc = dbo.fn_get_acc('CASH');

    SET @v_ar_acc = dbo.fn_get_acc('AR');

    ;WITH Affected AS (
      SELECT DISTINCT ra.invoice_id
      FROM dbo.receipt_apply ra
      WHERE ra.receipt_id = @p_receipt_id
    )
    UPDATE si
      SET si.paid_amount = si.paid_amount + ra.sum_applied
    FROM dbo.sales_invoices si
    INNER JOIN (
      SELECT invoice_id, SUM(amount_applied) AS sum_applied
      FROM dbo.receipt_apply
      WHERE receipt_id = @p_receipt_id
      GROUP BY invoice_id
    ) ra ON ra.invoice_id = si.invoice_id;

    ;WITH Affected AS (
      SELECT DISTINCT invoice_id
      FROM dbo.receipt_apply
      WHERE receipt_id = @p_receipt_id
    )
    UPDATE si
      SET status =
        CASE
          WHEN paid_amount >= total_amount THEN 'DA_THU'
          WHEN paid_amount > 0 THEN 'THU_MOT_PHAN'
          ELSE 'CHUA_THU'
        END
    FROM dbo.sales_invoices si
    INNER JOIN Affected a ON a.invoice_id = si.invoice_id;

    SET @v_je_no = CONCAT('JE-RC-', CONVERT(VARCHAR(8), GETDATE(), 112), '-', RIGHT('000000' + CAST(@p_receipt_id AS VARCHAR(20)), 6));

    INSERT INTO dbo.journal_entries (je_no, je_date, ref_type, ref_id, status, created_by)
    VALUES (@v_je_no, CAST(GETDATE() AS DATE), 'RECEIPT', @p_receipt_id, 'POSTED', @p_user_id);

    SET @v_je_id = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
    VALUES
      (@v_je_id, @v_cash_acc, @v_total, 0,        N'Thu tiền bán hàng'),
      (@v_je_id, @v_ar_acc,   0,        @v_total, N'Giảm công nợ khách hàng');

    UPDATE dbo.cash_receipts
    SET status='DA_GHI_SO', posted_by=@p_user_id, posted_at=SYSDATETIME(), cash_account_code=@v_cash_acc
    WHERE receipt_id = @p_receipt_id;

    INSERT INTO dbo.audit_logs (user_id, action, object_type, object_id, note)
    VALUES (@p_user_id, 'POST', 'RECEIPT', @p_receipt_id, 'Posted cash receipt');

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

CREATE PROCEDURE dbo.sp_unpost_receipt
  @p_receipt_id BIGINT,
  @p_user_id    INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @v_status   VARCHAR(20);
  DECLARE @v_je_id    BIGINT;
  DECLARE @v_rev_je_id BIGINT;
  DECLARE @v_rev_no   VARCHAR(60);

  BEGIN TRY
    BEGIN TRAN;

    SELECT @v_status = status
    FROM dbo.cash_receipts WITH (UPDLOCK, ROWLOCK)
    WHERE receipt_id = @p_receipt_id;

    IF @v_status IS NULL
      THROW 50000, 'Receipt not found', 1;

    IF @v_status <> 'DA_GHI_SO'
      THROW 50000, 'Only DA_GHI_SO receipts can be unposted', 1;

    UPDATE si
      SET si.paid_amount = si.paid_amount - ra.sum_applied
    FROM dbo.sales_invoices si
    INNER JOIN (
      SELECT invoice_id, SUM(amount_applied) AS sum_applied
      FROM dbo.receipt_apply
      WHERE receipt_id = @p_receipt_id
      GROUP BY invoice_id
    ) ra ON ra.invoice_id = si.invoice_id;

    ;WITH Affected AS (
      SELECT DISTINCT invoice_id
      FROM dbo.receipt_apply
      WHERE receipt_id = @p_receipt_id
    )
    UPDATE si
      SET status =
        CASE
          WHEN paid_amount >= total_amount THEN 'DA_THU'
          WHEN paid_amount > 0 THEN 'THU_MOT_PHAN'
          ELSE 'CHUA_THU'
        END
    FROM dbo.sales_invoices si
    INNER JOIN Affected a ON a.invoice_id = si.invoice_id;

    SELECT TOP (1) @v_je_id = je_id
    FROM dbo.journal_entries WITH (UPDLOCK, ROWLOCK)
    WHERE ref_type='RECEIPT' AND ref_id=@p_receipt_id AND status='POSTED'
    ORDER BY je_id DESC;

    IF @v_je_id IS NULL
      THROW 50000, 'Journal entry not found for this receipt', 1;

    SELECT @v_rev_no = CONCAT('REV-', je_no) FROM dbo.journal_entries WHERE je_id = @v_je_id;

    INSERT INTO dbo.journal_entries (je_no, je_date, ref_type, ref_id, status, created_by)
    VALUES (@v_rev_no, CAST(GETDATE() AS DATE), 'RECEIPT', @p_receipt_id, 'POSTED', @p_user_id);

    SET @v_rev_je_id = CAST(SCOPE_IDENTITY() AS BIGINT);

    INSERT INTO dbo.journal_lines (je_id, account_code, debit, credit, note)
    SELECT @v_rev_je_id, account_code, credit, debit, CONCAT('Reversal of JE#', @v_je_id)
    FROM dbo.journal_lines
    WHERE je_id = @v_je_id;

    UPDATE dbo.journal_entries
    SET status='REVERSED',
        reversed_by=@p_user_id,
        reversed_at=SYSDATETIME(),
        reversal_je_id=@v_rev_je_id,
        reverse_note='UNPOST receipt'
    WHERE je_id = @v_je_id;

    UPDATE dbo.cash_receipts
    SET status='NHAP', posted_by=NULL, posted_at=NULL
    WHERE receipt_id = @p_receipt_id;

    INSERT INTO dbo.audit_logs (user_id, action, object_type, object_id, note)
    VALUES (@p_user_id, 'UNPOST', 'RECEIPT', @p_receipt_id, 'Unposted cash receipt');

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

------------------------------------------------------------
-- 12) SAMPLE DATA (idempotent inserts)
------------------------------------------------------------
MERGE dbo.roles AS t
USING (VALUES
 (1,'admin'),
 (2,'giam_doc'),
 (3,'ke_toan'),
 (4,'kinh_doanh'),
 (5,'kho')
) AS s(role_id, role_name)
ON t.role_id = s.role_id
WHEN MATCHED THEN UPDATE SET role_name = s.role_name
WHEN NOT MATCHED THEN INSERT (role_id, role_name) VALUES (s.role_id, s.role_name);

MERGE dbo.warehouses AS t
USING (VALUES ('MAIN','Kho chính')) AS s(wh_code, wh_name)
ON t.wh_code = s.wh_code
WHEN MATCHED THEN UPDATE SET wh_name = s.wh_name
WHEN NOT MATCHED THEN INSERT (wh_code, wh_name) VALUES (s.wh_code, s.wh_name);

MERGE dbo.accounts AS t
USING (VALUES
 ('111', N'Tiền mặt', N'TÀI SẢN'),
 ('112', N'Tiền gửi ngân hàng', N'TÀI SẢN'),
 ('131', N'Phải thu khách hàng', N'TÀI SẢN'),
 ('152', N'Kho nguyên vật liệu', N'TÀI SẢN'),
 ('155', N'Kho thành phẩm', N'TÀI SẢN'),
 ('154', N'Chi phí SXKD dở dang (WIP)', N'TÀI SẢN'),
 ('331', N'Phải trả nhà cung cấp', N'NỢ PHẢI TRẢ'),
 ('711', N'Thu nhập khác (chênh lệch tồn)', N'DOANH THU'),
 ('811', N'Chi phí khác (chênh lệch tồn)', N'CHI PHÍ')
) AS s(account_code, account_name, acc_type)
ON t.account_code = s.account_code
WHEN MATCHED THEN UPDATE SET account_name = s.account_name, acc_type = s.acc_type
WHEN NOT MATCHED THEN INSERT (account_code, account_name, acc_type) VALUES (s.account_code, s.account_name, s.acc_type);

MERGE dbo.sys_account_defaults AS t
USING (VALUES
 ('CASH', '111'),
 ('BANK', '112'),
 ('AR',   '131'),
 ('INV_NVL','152'),
 ('INV_TP','155'),
 ('WIP',  '154'),
 ('AP',   '331'),
 ('INV_GAIN','711'),
 ('INV_LOSS','811')
) AS s(key_name, account_code)
ON t.key_name = s.key_name
WHEN MATCHED THEN UPDATE SET account_code = s.account_code
WHEN NOT MATCHED THEN INSERT (key_name, account_code) VALUES (s.key_name, s.account_code);

IF NOT EXISTS (SELECT 1 FROM dbo.[users] WHERE email = 'admin@gmail.com')
BEGIN
  INSERT INTO dbo.[users] (full_name, email, [password], role_id)
  VALUES
   ('Nguyen Van Admin',    'admin@gmail.com', '123456', 1),
   ('Nguyen Van GiamDoc',  'gd@gmail.com',    '123456', 2),
   ('Nguyen Van KeToan',   'kt@gmail.com',    '123456', 3),
   ('Nguyen Van KinhDoanh','kd@gmail.com',    '123456', 4),
   ('Nguyen Van Kho',      'kho@gmail.com',   '123456', 5);
END

IF NOT EXISTS (SELECT 1 FROM dbo.customers WHERE customer_code = 'KH001')
BEGIN
  INSERT INTO dbo.customers (customer_code, customer_name, address, tax_code, phone)
  VALUES ('KH001', N'Công ty A', N'HCM', '0312345678', '0909000000');
END

IF NOT EXISTS (SELECT 1 FROM dbo.suppliers WHERE supplier_code = 'NCC001')
BEGIN
  INSERT INTO dbo.suppliers (supplier_code, supplier_name, address, tax_code, phone)
  VALUES ('NCC001', N'Nhà cung cấp 1', N'HCM', '0311111111', '0909111111');
END

IF NOT EXISTS (SELECT 1 FROM dbo.items WHERE item_code = 'NVL001')
BEGIN
  INSERT INTO dbo.items (item_code, item_name, uom, item_type, default_cost, inv_account_code)
  VALUES
   ('NVL001', N'Giấy A4', N'ram', 'NVL', 50000, '152');
END

IF NOT EXISTS (SELECT 1 FROM dbo.items WHERE item_code = 'TP001')
BEGIN
  INSERT INTO dbo.items (item_code, item_name, uom, item_type, default_cost, inv_account_code)
  VALUES
   ('TP001', N'Hộp giấy thành phẩm', N'cái', 'TP', 0, '155');
END
GO
