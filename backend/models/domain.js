'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Domain extends Model {
    static associate(models) {
      Domain.hasMany(models.DatabaseEngine, { foreignKey: 'domain_id', as: 'engines' });
    }
  }
  Domain.init(
    {
      name: { type: DataTypes.STRING(100), allowNull: false },
      description: { type: DataTypes.TEXT },
    },
    {
      sequelize,
      modelName: 'Domain',
      tableName: 'domains',
      underscored: true,
    }
  );
  return Domain;
};
