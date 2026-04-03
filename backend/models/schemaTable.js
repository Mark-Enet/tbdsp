'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaTable extends Model {
    static associate(models) {
      SchemaTable.belongsTo(models.DatabaseEngine, { foreignKey: 'engine_id', as: 'engine' });
      SchemaTable.hasMany(models.SchemaColumn, { foreignKey: 'table_id', as: 'columns' });
      SchemaTable.hasMany(models.SchemaIndex, { foreignKey: 'table_id', as: 'indexes' });
      SchemaTable.hasMany(models.SchemaForeignKey, { foreignKey: 'table_id', as: 'foreignKeys' });
    }
  }
  SchemaTable.init(
    {
      engineId: { type: DataTypes.INTEGER, allowNull: false, field: 'engine_id' },
      name: { type: DataTypes.STRING(150), allowNull: false },
      tableComment: { type: DataTypes.TEXT, field: 'table_comment' },
    },
    {
      sequelize,
      modelName: 'SchemaTable',
      tableName: 'schema_tables',
      underscored: true,
    }
  );
  return SchemaTable;
};
