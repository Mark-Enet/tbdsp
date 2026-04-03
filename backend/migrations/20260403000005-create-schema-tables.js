'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_tables', {
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
        type: Sequelize.STRING(150),
        allowNull: false,
      },
      table_comment: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      created_at: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('NOW()'),
      },
      updated_at: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('NOW()'),
      },
    });
    await queryInterface.addIndex('schema_tables', ['engine_id', 'name'], {
      unique: true,
      name: 'uq_schema_tables_engine_name',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_tables');
  },
};
