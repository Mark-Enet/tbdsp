'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SchemaFile extends Model {
    static associate(models) {
      SchemaFile.belongsTo(models.DatabaseEngine, { foreignKey: 'engine_id', as: 'engine' });
    }
  }
  SchemaFile.init(
    {
      engineId: { type: DataTypes.INTEGER, allowNull: false, field: 'engine_id' },
      fileKey: { type: DataTypes.STRING(50), allowNull: false, field: 'file_key' },
      relPath: { type: DataTypes.TEXT, allowNull: false, field: 'rel_path' },
    },
    {
      sequelize,
      modelName: 'SchemaFile',
      tableName: 'schema_files',
      underscored: true,
    }
  );
  return SchemaFile;
};
