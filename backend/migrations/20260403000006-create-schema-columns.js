'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_columns', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER,
      },
      table_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'schema_tables', key: 'id' },
        onDelete: 'CASCADE',
      },
      name: {
        type: Sequelize.STRING(150),
        allowNull: false,
      },
      data_type: {
        type: Sequelize.STRING(100),
        allowNull: false,
      },
      is_nullable: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      },
      default_value: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      is_primary_key: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      column_comment: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      position: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
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
    await queryInterface.addIndex('schema_columns', ['table_id', 'name'], {
      unique: true,
      name: 'uq_schema_columns_table_name',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_columns');
  },
};
