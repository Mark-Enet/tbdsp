'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaEnum extends Model {
    static associate(models) {
      SchemaEnum.belongsTo(models.DatabaseEngine, { foreignKey: 'engine_id', as: 'engine' });
    }
  }
  SchemaEnum.init(
    {
      engineId: { type: DataTypes.INTEGER, allowNull: false, field: 'engine_id' },
      name: { type: DataTypes.STRING(100), allowNull: false },
      values: { type: DataTypes.JSONB, allowNull: false, defaultValue: [] },
    },
    {
      sequelize,
      modelName: 'SchemaEnum',
      tableName: 'schema_enums',
      underscored: true,
      timestamps: false,
    }
  );
  return SchemaEnum;
};
