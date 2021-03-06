/***************************************************************************
**
** Copyright (C) 2012 Marko Koschak (marko.koschak@tisno.de)
** All rights reserved.
**
** This file is part of ownKeepass.
**
** ownKeepass is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 2 of the License, or
** (at your option) any later version.
**
** ownKeepass is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with ownKeepass.  If not, see <http://www.gnu.org/licenses/>.
**
***************************************************************************/

#include <QDebug>
#include "KdbListModel.h"
#include "private/KdbInterface.h"

using namespace kpxPublic;
using namespace kpxPrivate;

KdbListModel::KdbListModel(QObject *parent)
    : QAbstractListModel(parent),
      m_modelId(0),
      m_registered(false),
      m_searchRootGroupId(0)
{
    // connect signals to backend
    bool ret = connect(this, SIGNAL(loadMasterGroups()),
                       KdbInterface::getInstance()->getWorker(), SLOT(slot_loadMasterGroups()));
    Q_ASSERT(ret);
    ret = connect(this, SIGNAL(loadGroupsAndEntries(int)),
                  KdbInterface::getInstance()->getWorker(), SLOT(slot_loadGroupsAndEntries(int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(groupsAndEntriesLoaded(int)),
                  this, SIGNAL(groupsAndEntriesLoaded(int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(addItemToListModel(QString, QString, int, int, int)),
                  this, SLOT(slot_addItemToListModel(QString, QString, int, int, int)));
    Q_ASSERT(ret);
    ret = connect(this, SIGNAL(unregisterFromKdbInterface(int)),
                  KdbInterface::getInstance()->getWorker(), SLOT(slot_unregisterListModel(int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(updateItemInListModel(QString,QString,int,int)),
                  this, SLOT(slot_updateItemInListModel(QString,QString,int,int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(masterGroupsLoaded(int)),
                  this, SIGNAL(masterGroupsLoaded(int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(deleteItemInListModel(int)),
                  this, SLOT(slot_deleteItem(int)));
    Q_ASSERT(ret);
    ret = connect(this, SIGNAL(searchEntries(QString,int)),
                  KdbInterface::getInstance()->getWorker(), SLOT(slot_searchEntries(QString,int)));
    Q_ASSERT(ret);
    ret = connect(KdbInterface::getInstance()->getWorker(), SIGNAL(searchEntriesCompleted(int)),
                  this, SIGNAL(searchEntriesCompleted(int)));
    Q_ASSERT(ret);
}

KdbListModel::~KdbListModel()
{
    if (m_registered) {
        emit unregisterFromKdbInterface(m_modelId);
    }
}

/// slot which adds a new item to the data model
void KdbListModel::slot_addItemToListModel(QString title, QString subtitle, int id, int itemType, int modelId)
{
//    qDebug() << "KdbListModel::slot_addItemToListModel (m_modelId: " << m_modelId << " modelId: " << modelId << ")";
    if (!m_registered) {
        m_modelId = modelId;
        m_registered = true;
    }
    if (m_modelId == modelId) {
        KdbItem item(title, subtitle, id, itemType);
        if (itemType == kpxPublic::KdbListModel::ENTRY) {
            // append new entry to end of list
            beginInsertRows(QModelIndex(), rowCount(), rowCount());
            m_items << item;
            endInsertRows();
        } else {
            // insert new group after last group in list
            int i = 0;
            while (i < m_items.count() && m_items[i].m_itemType == kpxPublic::KdbListModel::GROUP) ++i;
            beginInsertRows(QModelIndex(), i, i);
            m_items.insert(i, item);
            endInsertRows();
        }
        // emit isEmptyChanged signal if list view was empty before
        if (m_items.length() == 1) {
            emit isEmptyChanged();
        }

//        qDebug("slot_addItemToListModel - added: %s", CSTR(title));
    }

    // signal to property to update itself in QML
    emit modelDataChanged();
}

/*!
 * \brief KdbListModel::slot_updateItemInListModel
 * This function updates a single groups item in the list model data.
 *
 * \param title The detail that should be changed in the item.
 * \param groupId Identifier for the item inside of the list model.
 * \param modelId Identifier for list model, which needs to be changed.
 */
void KdbListModel::slot_updateItemInListModel(QString title, QString subTitle, int groupId, int modelId)

{
    qDebug() << "KdbListModel::slot_deleteItem (m_modelId: " << m_modelId << " modelId: " << modelId << " groupId: " << groupId << ")";

    // check if we need to do anything
    if (m_modelId == modelId) {
        // look at each item in list model
        for (int i = 0; i < m_items.count(); i++) {
            if (m_items[i].m_id == groupId) {
                // set new title name
                beginResetModel();
                m_items[i].m_name = title;
                m_items[i].m_subtitle = subTitle;
                endResetModel();
            }
        }

        // signal to property to update itself in QML
        emit modelDataChanged();
    }
}

void KdbListModel::loadMasterGroupsFromDatabase()
{
    // make list view empty and unregister if necessary
    if (!isEmpty()) {
        clear();
    }
    if (m_registered) {
        emit unregisterFromKdbInterface(m_modelId);
        m_registered = false;
    }
    // send signal to global interface of keepass database to get master groups
    emit loadMasterGroups();
}

void KdbListModel::loadGroupsAndEntriesFromDatabase(int groupId)
{
    // make list view empty and unregister if necessary
    if (!isEmpty()) {
        clear();
    }
    if (m_registered) {
        emit unregisterFromKdbInterface(m_modelId);
        m_registered = false;
    }
    // send signal to global interface of keepass database to get entries and subgroups
    emit loadGroupsAndEntries(groupId);
}

int KdbListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_items.count();
}

bool KdbListModel::isEmpty()
{
    return m_items.isEmpty();
}

QVariant KdbListModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_items.count())
        return QVariant();

    return m_items[index.row()].get(role);
}

void KdbListModel::clear()
{
    beginResetModel();
    m_items.clear();
    endResetModel();

    // signal to QML and for property update
    emit modelDataChanged();
    emit isEmptyChanged();
}

void KdbListModel::clearListModel()
{
    clear();
}

void KdbListModel::slot_deleteItem(int itemId)
{
    qDebug() << "KdbListModel::slot_deleteItem (modelId: " << m_modelId << " itemId: " << itemId << ")";

    // look at each item in list model
    for (int i = 0; i < m_items.count(); i++) {
        if (m_items[i].m_id == itemId) {
            // found it, delete it from list model
            beginRemoveRows(QModelIndex(), i, i);
            m_items.removeAt(i);
            endRemoveRows();
            // signal to property to update itself in QML
            emit modelDataChanged();
            // emit isEmptyChanged signal if last item was deleted
            if (m_items.isEmpty()) {
                emit isEmptyChanged();
            }
        }
    }
}

void KdbListModel::searchEntriesInKdbDatabase(QString searchString)
{
    qDebug("KdbListModel::searchEntriesInKdbDatabase()");

    // make list view empty and unregister if necessary
    if (!isEmpty()) {
        clear();
    }
    if (m_registered) {
        emit unregisterFromKdbInterface(m_modelId);
    }

    // list model for searching is -1 per default, so set it here already
    m_modelId = -1;
    m_registered = true;

    // send signal to backend to start search in database
    emit searchEntries(searchString, m_searchRootGroupId);
}
