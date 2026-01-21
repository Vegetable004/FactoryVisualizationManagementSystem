SELECT DATABASE();

-- 可视化看板指标：总览、库存、采购、销售、生产----------------

-- 1) 物料主数据：对应单据的“物料代号/物料名称/规格/单位”
CREATE TABLE material (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(128) NOT NULL,
  spec VARCHAR(255),
  unit VARCHAR(16) NOT NULL DEFAULT 'PCS',
  type ENUM('FG','RM','WIP','OTHER') DEFAULT 'OTHER',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2) 仓库
CREATE TABLE warehouse (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(128) NOT NULL,
  address VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3) 库存余额（看板核心）
CREATE TABLE stock (
  material_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL,
  qty DECIMAL(18,6) NOT NULL DEFAULT 0,
  PRIMARY KEY (material_id, warehouse_id),
  CONSTRAINT fk_stock_material FOREIGN KEY (material_id) REFERENCES material(id),
  CONSTRAINT fk_stock_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id)
) ENGINE=InnoDB;

-- 4) 出入库单头：就是你这张“送货单/出货单”的单号、日期、收发货信息
CREATE TABLE stock_doc (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  doc_no VARCHAR(64) NOT NULL UNIQUE,                 -- NO.260104
  doc_type ENUM('IN','OUT','ADJUST','ISSUE') NOT NULL,-- 入库/出库/调整/生产领料
  doc_date DATE NOT NULL,                             -- 2026-01-07
  from_party VARCHAR(128),                            -- 发货单位/发出方
  to_party VARCHAR(128),                              -- 收货单位/收货方
  handler VARCHAR(64),                                -- 经办人
  remark VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 5) 出入库单明细：单据每一行
CREATE TABLE stock_doc_line (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  doc_id BIGINT NOT NULL,
  line_no INT NOT NULL,
  material_id BIGINT NOT NULL,
  qty DECIMAL(18,6) NOT NULL,
  remark VARCHAR(255),
  CONSTRAINT fk_line_doc FOREIGN KEY (doc_id) REFERENCES stock_doc(id) ON DELETE CASCADE,
  CONSTRAINT fk_line_material FOREIGN KEY (material_id) REFERENCES material(id),
  UNIQUE KEY uk_doc_line (doc_id, line_no)
) ENGINE=InnoDB;

-- 6) 库存流水：用于追溯与趋势图
CREATE TABLE stock_txn (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  txn_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  doc_no VARCHAR(64) NOT NULL,
  doc_type ENUM('IN','OUT','ADJUST','ISSUE') NOT NULL,
  material_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL,
  qty_change DECIMAL(18,6) NOT NULL,                  -- +入库，-出库
  line_id BIGINT NULL,
  CONSTRAINT fk_txn_material FOREIGN KEY (material_id) REFERENCES material(id),
  CONSTRAINT fk_txn_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id)
) ENGINE=InnoDB;

CREATE INDEX idx_txn_time ON stock_txn(txn_time);
CREATE INDEX idx_txn_doc  ON stock_txn(doc_no);
CREATE INDEX idx_txn_mat  ON stock_txn(material_id);

-- 7) 生产工单（极简）
CREATE TABLE mo (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  mo_no VARCHAR(64) NOT NULL UNIQUE,
  product_id BIGINT NOT NULL,                         -- 成品(material.type='FG')
  plan_qty DECIMAL(18,6) NOT NULL,
  status ENUM('PLANNED','IN_PROCESS','DONE','CLOSED') DEFAULT 'PLANNED',
  start_date DATE NULL,
  due_date DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mo_product FOREIGN KEY (product_id) REFERENCES material(id)
) ENGINE=InnoDB;

-- 8) 生产领料：对应“工单领料单”，也会写入 stock_txn (ISSUE) 并更新 stock
CREATE TABLE mo_issue (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  mo_id BIGINT NOT NULL,
  material_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL,
  qty DECIMAL(18,6) NOT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_issue_mo FOREIGN KEY (mo_id) REFERENCES mo(id) ON DELETE CASCADE,
  CONSTRAINT fk_issue_material FOREIGN KEY (material_id) REFERENCES material(id),
  CONSTRAINT fk_issue_wh FOREIGN KEY (warehouse_id) REFERENCES warehouse(id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;












