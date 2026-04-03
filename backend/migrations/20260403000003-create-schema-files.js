'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_files', {
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
      file_key: {
        type: Sequelize.STRING(50),
        allowNull: false,
        comment: 'schema | sample_data | readme | erd',
      },
      rel_path: {
        type: Sequelize.TEXT,
        allowNull: false,
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
    await queryInterface.addIndex('schema_files', ['engine_id', 'file_key'], {
      unique: true,
      name: 'uq_schema_files_engine_key',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_files');
  },
};
