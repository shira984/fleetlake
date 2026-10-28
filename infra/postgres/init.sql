-- Runs once, on first start of an empty Postgres volume.

CREATE DATABASE iceberg_catalog;
CREATE DATABASE prefect;

\connect iceberg_catalog

-- Iceberg JDBC catalog tables (schema V0, as documented for Trino's JDBC catalog).
-- Trino and PyIceberg's SqlCatalog both read and write these, so they share one catalog.
CREATE TABLE IF NOT EXISTS iceberg_namespace_properties (
    catalog_name   VARCHAR(255) NOT NULL,
    namespace      VARCHAR(255) NOT NULL,
    property_key   VARCHAR(255),
    property_value VARCHAR(5500),
    PRIMARY KEY (catalog_name, namespace, property_key)
);

CREATE TABLE IF NOT EXISTS iceberg_tables (
    catalog_name               VARCHAR(255) NOT NULL,
    table_namespace            VARCHAR(255) NOT NULL,
    table_name                 VARCHAR(255) NOT NULL,
    metadata_location          VARCHAR(5500),
    previous_metadata_location VARCHAR(5500),
    PRIMARY KEY (catalog_name, table_namespace, table_name)
);
