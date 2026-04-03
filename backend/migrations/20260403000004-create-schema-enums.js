'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_enums', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER,
      },
      engine_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'database_engines', key: 'id' },
        onDelete: 'CASCADE',
      },
      name: {
        type: Sequelize.STRING(100),
        allowNull: false,
      },
      values: {
        type: Sequelize.JSONB,
        allowNull: false,
        defaultValue: '[]',
        comment: 'Ordered array of enum value strings',
      },
    });
    await queryInterface.addIndex('schema_enums', ['engine_id', 'name'], {
      unique: true,
      name: 'uq_schema_enums_engine_name',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_enums');
  },
};
