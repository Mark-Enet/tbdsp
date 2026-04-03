'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('database_engines', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER,
      },
      domain_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'domains', key: 'id' },
        onDelete: 'CASCADE',
      },
      engine: {
        type: Sequelize.STRING(50),
        allowNull: false,
      },
      version_note: {
        type: Sequelize.STRING(100),
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
    await queryInterface.addIndex('database_engines', ['domain_id', 'engine'], {
      unique: true,
      name: 'uq_database_engines_domain_engine',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('database_engines');
  },
};
