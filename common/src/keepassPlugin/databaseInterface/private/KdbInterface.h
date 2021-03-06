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

#ifndef KDBINTERFACE_H
#define KDBINTERFACE_H

#include <QObject>
#include <QThread>

#include "KdbInterfaceWorker.h"

namespace kpxPrivate {

class KdbInterface : public QObject
{
    Q_OBJECT

public:
    virtual ~KdbInterface();

    static KdbInterface* getInstance();

    // access to internal worker needed to connect to its slots
    KdbInterfaceWorker* getWorker() { return &m_worker; }

private:
    // Prevent object creation, it will be created as singleton object
    KdbInterface(QObject* parent = 0);
    Q_DISABLE_COPY(KdbInterface)

    QThread m_workerThread;
    KdbInterfaceWorker m_worker;
    static KdbInterface* m_Instance;
};

}
#endif // KDBINTERFACE_H
