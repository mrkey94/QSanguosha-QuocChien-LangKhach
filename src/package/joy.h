#ifndef JOYPACKAGE_H
#define JOYPACKAGE_H

#include "package.h"
#include "standard.h"

class JoyPackage : public Package
{
    Q_OBJECT

public:
    JoyPackage();
};

class DisasterPackage : public Package
{
    Q_OBJECT

public:
    DisasterPackage();
};

//class JoyEquipPackage : public Package
//{
//    Q_OBJECT

//public:
//    JoyEquipPackage();
//};

class Shit: public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Shit(Card::Suit suit, int number);
    QString getSubtype() const;

//    static bool HasShit(const Card *card);
};



// five disasters:

class Deluge : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Deluge(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Typhoon : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Typhoon(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Earthquake : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Earthquake(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class Volcano : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE Volcano(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

class MudSlide : public Disaster
{
    Q_OBJECT

public:
    Q_INVOKABLE MudSlide(Card::Suit suit, int number);
    void takeEffect(ServerPlayer *target) const;
};

//class Monkey : public OffensiveHorse
//{
//    Q_OBJECT

//public:
//    Q_INVOKABLE Monkey(Card::Suit suit, int number);
//};

//class GaleShell :public Armor
//{
//    Q_OBJECT

//public:
//    Q_INVOKABLE GaleShell(Card::Suit suit, int number);

//    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
//};

//class YxSword : public Weapon
//{
//    Q_OBJECT

//public:
//    Q_INVOKABLE YxSword(Card::Suit suit, int number);
//};

//class FiveLines : public Armor
//{
//    Q_OBJECT

//public:
//    Q_INVOKABLE FiveLines(Card::Suit suit, int number);

//    void onInstall(ServerPlayer *player) const;
//};

#endif // JOYPACKAGE_H
