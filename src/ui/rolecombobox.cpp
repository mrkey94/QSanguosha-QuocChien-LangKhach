/********************************************************************
    Copyright (c) 2013-2015 - Mogara

    This file is part of QSanguosha-Hegemony.

    This game is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 3.0
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    See the LICENSE file for more details.

    Mogara
    *********************************************************************/

#include "rolecombobox.h"
#include "skinbank.h"
#include "roomscene.h"
#include "engine.h"

void RoleComboBox::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (!fixed_role.isEmpty() || circle) return;
    QPoint point = QPoint(event->pos().x(), event->pos().y());;
    if (expanding && !boundingRect().contains(point)) {
        expanding = false;
        update();
        return;
    } else if (!expanding) {
        expanding = true;
        update();
        return;
    }
    QStringList kingdoms = Sanguosha->getKingdoms();
    kingdoms.removeAll("god");
    kingdoms.removeAll("careerist");
    foreach (const QString &kingdom, kingdoms) {
        if (G_COMMON_LAYOUT.m_rolesRect.value(kingdom, QRect()).contains(point)) {
            kingdoms_excluded[kingdom] = !kingdoms_excluded.value(kingdom);
            break;
        }
    }
    update();
}

void RoleComboBox::paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *)
{
    /*
      --------------------
      --------------------
      ||       ||       ||
      ||  WEI  ||  QUN  ||
      ||       ||       ||
      --------------------
      --------------------
      ||       ||       ||
      ||  SHU  ||  WU   ||
      ||       ||       ||
      --------------------
      --------------------
      */
    double scale = G_ROOM_LAYOUT.scale;
    if (!fixed_role.isEmpty()) {
        QPixmap pix;
        QString file;
        int x, y;
        if (m_player && m_player->isBigKingdomPlayer()) {
            file = "image/system/roles/big/%1.png";
            x = -6; y = -6;
        } else {
            file = "image/system/roles/%1.png";
            x = 0; y = 0;
        }
        pix.load(file.arg(fixed_role));
        painter->drawPixmap(x, y, (int)(pix.width() * scale),(int)(pix.height() * scale), pix);
        return;
    }
    QStringList kingdoms = Sanguosha->getKingdoms();
    kingdoms.removeAll("god");
    kingdoms.removeAll("careerist");
    if (!expanding) {
        if (circle) {
            QPixmap pix;
            pix.load("image/system/roles/unknown.png");
            painter->drawPixmap(1, 0, (int)(28 * scale), (int)(28 * scale), pix);
        } else {
            QColor grey = G_COMMON_LAYOUT.m_roleDarkColor;
            QPen pen(Qt::black);
            pen.setWidth(1);
            painter->setPen(pen);

            int index = 0;
            foreach (const QString &kingdom, kingdoms) {
                painter->setBrush(QBrush(kingdoms_excluded.value(kingdom) ? grey : G_COMMON_LAYOUT.m_rolesColor.value(kingdom)));
                painter->drawRect(COMPACT_BORDER_WIDTH + ((index % 2) ? COMPACT_BORDER_WIDTH + COMPACT_ITEM_LENGTH : 0), COMPACT_BORDER_WIDTH + (COMPACT_BORDER_WIDTH + COMPACT_ITEM_LENGTH) * (index / 2), COMPACT_ITEM_LENGTH, COMPACT_ITEM_LENGTH);
                ++index;
            }
        }
    } else {
        QPixmap pix = G_ROOM_SKIN.getPixmap(QSanRoomSkin::S_SKIN_KEY_EXPANDING_ROLE_BOX);
        painter->drawPixmap(0, 0, (int)(pix.width() * scale),(int)(pix.height() * scale), pix);

        foreach (const QString &kingdom, kingdoms) {
            if (kingdoms_excluded.value(kingdom))
                painter->drawPixmap(G_COMMON_LAYOUT.m_rolesRect.value(kingdom), G_ROOM_SKIN.getPixmap(QSanRoomSkin::S_SKIN_KEY_ROLE_BOX_KINGDOM_MASK, kingdom));
        }
    }
}

QRectF RoleComboBox::boundingRect() const
{
    double scale = G_ROOM_LAYOUT.scale;
    static QRect rect = G_ROOM_SKIN.getPixmap(QSanRoomSkin::S_SKIN_KEY_EXPANDING_ROLE_BOX).rect();
    return QRectF(rect.x(), rect.y(), (int)(rect.width() * scale), (int)(rect.height() * scale));
}

RoleComboBox::RoleComboBox(QGraphicsItem *photo, ClientPlayer *player, bool circle)
    : QGraphicsObject(photo), m_player(player), circle(circle), expanding(false)
{
    QStringList kingdoms = Sanguosha->getKingdoms();
    kingdoms.removeAll("god");
    kingdoms.removeAll("careerist");
    foreach(const QString &kingdom, kingdoms)
        kingdoms_excluded[kingdom] = false;
    connect(RoomSceneInstance, &RoomScene::cancel_role_box_expanding, this, &RoleComboBox::mouseClickedOutside);
    setAcceptedMouseButtons(Qt::LeftButton);
}

void RoleComboBox::setPlayer(ClientPlayer *player)
{
    m_player = player;
    update();
}

void RoleComboBox::fix(const QString &role)
{
    if (role == "god") return;
    fixed_role = role;
    update();
}

void RoleComboBox::mouseClickedOutside()
{
    if (!expanding) return;
    expanding = false;
    update();
}
