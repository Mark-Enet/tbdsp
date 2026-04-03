'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('schema_indexes', {
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
      index_type: {
        type: Sequelize.STRING(50),
        allowNull: false,
        defaultValue: 'btree',
        comment: 'btree | hash | gin | gist | brin | spgist',
      },
      is_unique: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      is_partial: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      where_clause: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      columns: {
        type: Sequelize.JSONB,
        allowNull: false,
        defaultValue: '[]',
        comment: 'Ordered array of indexed column names',
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
    await queryInterface.addIndex('schema_indexes', ['table_id', 'name'], {
      unique: true,
      name: 'uq_schema_indexes_table_name',
    });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('schema_indexes');
  },
};
