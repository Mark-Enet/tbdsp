'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaColumn extends Model {
    static associate(models) {
      SchemaColumn.belongsTo(models.SchemaTable, { foreignKey: 'table_id', as: 'table' });
    }
  }
  SchemaColumn.init(
    {
      tableId: { type: DataTypes.INTEGER, allowNull: false, field: 'table_id' },
      name: { type: DataTypes.STRING(150), allowNull: false },
      dataType: { type: DataTypes.STRING(100), allowNull: false, field: 'data_type' },
      isNullable: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true, field: 'is_nullable' },
      defaultValue: { type: DataTypes.TEXT, field: 'default_value' },
      isPrimaryKey: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false, field: 'is_primary_key' },
      columnComment: { type: DataTypes.TEXT, field: 'column_comment' },
      position: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    },
    {
      sequelize,
      modelName: 'SchemaColumn',
      tableName: 'schema_columns',
      underscored: true,
    }
  );
  return SchemaColumn;
};
