'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_foreign_keys', {
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
      constraint_name: {
        type: Sequelize.STRING(150),
        allowNull: true,
      },
      from_columns: {
        type: Sequelize.JSONB,
        allowNull: false,
        defaultValue: '[]',
        comment: 'Ordered array of local column names',
      },
      to_table: {
        type: Sequelize.STRING(150),
        allowNull: false,
      },
      to_columns: {
        type: Sequelize.JSONB,
        allowNull: false,
        defaultValue: '[]',
        comment: 'Ordered array of referenced column names',
      },
      on_delete: {
        type: Sequelize.STRING(50),
        allowNull: true,
        comment: 'CASCADE | SET NULL | SET DEFAULT | RESTRICT | NO ACTION',
      },
      on_update: {
        type: Sequelize.STRING(50),
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
    await queryInterface.addIndex('schema_foreign_keys', ['table_id'], {
      name: 'idx_schema_foreign_keys_table_id',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_foreign_keys');
  },
};
