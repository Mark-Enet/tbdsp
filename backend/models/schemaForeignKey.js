'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaForeignKey extends Model {
    static associate(models) {
      SchemaForeignKey.belongsTo(models.SchemaTable, { foreignKey: 'table_id', as: 'table' });
    }
  }
  SchemaForeignKey.init(
    {
      tableId: { type: DataTypes.INTEGER, allowNull: false, field: 'table_id' },
      constraintName: { type: DataTypes.STRING(150), field: 'constraint_name' },
      fromColumns: { type: DataTypes.JSONB, allowNull: false, defaultValue: [], field: 'from_columns' },
      toTable: { type: DataTypes.STRING(150), allowNull: false, field: 'to_table' },
      toColumns: { type: DataTypes.JSONB, allowNull: false, defaultValue: [], field: 'to_columns' },
      onDelete: { type: DataTypes.STRING(50), field: 'on_delete' },
      onUpdate: { type: DataTypes.STRING(50), field: 'on_update' },
    },
    {
      sequelize,
      modelName: 'SchemaForeignKey',
      tableName: 'schema_foreign_keys',
      underscored: true,
    }
  );
  return SchemaForeignKey;
};
