'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaIndex extends Model {
    static associate(models) {
      SchemaIndex.belongsTo(models.SchemaTable, { foreignKey: 'table_id', as: 'table' });
    }
  }
  SchemaIndex.init(
    {
      tableId: { type: DataTypes.INTEGER, allowNull: false, field: 'table_id' },
      name: { type: DataTypes.STRING(150), allowNull: false },
      indexType: { type: DataTypes.STRING(50), allowNull: false, defaultValue: 'btree', field: 'index_type' },
      isUnique: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false, field: 'is_unique' },
      isPartial: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false, field: 'is_partial' },
      whereClause: { type: DataTypes.TEXT, field: 'where_clause' },
      columns: { type: DataTypes.JSONB, allowNull: false, defaultValue: [] },
    },
    {
      sequelize,
      modelName: 'SchemaIndex',
      tableName: 'schema_indexes',
      underscored: true,
    }
  );
  return SchemaIndex;
};
