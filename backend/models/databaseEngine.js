'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class DatabaseEngine extends Model {
    static associate(models) {
      DatabaseEngine.belongsTo(models.Domain, { foreignKey: 'domain_id', as: 'domain' });
      DatabaseEngine.hasMany(models.SchemaTable, { foreignKey: 'engine_id', as: 'tables' });
      DatabaseEngine.hasMany(models.SchemaEnum, { foreignKey: 'engine_id', as: 'enums' });
      DatabaseEngine.hasMany(models.SchemaFile, { foreignKey: 'engine_id', as: 'files' });
    }
  }
  DatabaseEngine.init(
    {
      domainId: { type: DataTypes.INTEGER, allowNull: false, field: 'domain_id' },
      engine: { type: DataTypes.STRING(50), allowNull: false },
      versionNote: { type: DataTypes.STRING(100), field: 'version_note' },
    },
    {
      sequelize,
      modelName: 'DatabaseEngine',
      tableName: 'database_engines',
      underscored: true,
    }
  );
  return DatabaseEngine;
};
