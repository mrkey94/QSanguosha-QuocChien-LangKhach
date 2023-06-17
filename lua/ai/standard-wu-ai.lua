--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

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
*********************************************************************]]
--孙权
local zhiheng_skill = {}
zhiheng_skill.name = "zhiheng"
table.insert(sgs.ai_skills, zhiheng_skill)
zhiheng_skill.getTurnUseCard = function(self)
	--有一个BUG:玩家带着夜明珠开五谷托管,AI和玩家可以分别用一次制衡
	--问题在于玩家使用的时候记录的P:hasUsed("ZhihengLPCard"),AI用的时候记录的P:hasUsed("ZhihengCard")
	--[[
	--很奇怪,玩家可以用ZhihengLPCard,而AI进入ai_skill_use_func.ZhihengLPCard后不能使用use.card = sgs.Card_Parse("@ZhihengLPCard=" .. table.concat(use_cards, "+") .. "&LuminousPearl")
	local skill_card = sgs.Card_Parse("@ZhihengLPCard=.&LuminousPearl")
	assert(skill_card)
	skill_card:addSubcards(P:getCards("h"))
	R:useCard(sgs.CardUseStruct(skill_card, P, sgs.SPlayerList()), false)
	Global_room:writeToConsole(tostring(P:usedTimes("ZhihengLPCard")))
	Global_room:writeToConsole(tostring(P:usedTimes("ZhihengCard")))
	--]]
	--addPlayerHistory可以限制玩家发动夜明珠制衡,弃置夜明珠后会清空usedTimes,所以可以从弃牌堆拿回来再次发动夜明珠制衡
	if self.player:hasUsed("ZhihengCard") then return end--限一次(包括夜明珠)
	--因为夜明珠源码是视为拥有制衡,带着夜明珠可以查到P:hasSkill("zhiheng")为true,AI仍可以调用制衡的getTurnUseCard使用ZhihengCard
	if self.player:hasTreasure("LuminousPearl") and not self.player:hasUsed("ZhihengLPCard") and not self.player:ownSkill("zhiheng") then
		return sgs.Card_Parse("@ZhihengLPCard=.LuminousPearl")--装备夜明珠且没有明置制衡时优先使用夜明珠(使用夜明珠后仍然可以再亮将使用制衡)
	elseif self.player:ownSkill("zhiheng") and not self.player:hasUsed("ZhihengCard") and (self:willShowForAttack() or self:willShowForDefence()) then
		return sgs.Card_Parse("@ZhihengCard=.&zhiheng")
	end
end

sgs.ai_skill_use_func.ZhihengCard = function(c, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local unlimited = false
	if self.player:hasTreasure("LuminousPearl") and (self.player:inHeadSkills("zhiheng") or self.player:inDeputySkills("zhiheng")) then--self.player:ownSkill("zhiheng")
		unlimited = true
	end
	local all_dis = (self.player:hasSkill("lirang") and #self.friends_noself > 0)
	local show = "&zhiheng"
	local use_LP = false
	if not self.player:ownSkill("zhiheng") then show = "" end
	if self.player:hasTreasure("LuminousPearl") and not self.player:hasUsed("ZhihengLPCard") and not self.player:ownSkill("zhiheng") then
		use_LP = true
	end
	local skill = sgs.Sanguosha:getSkill("zhiheng")
	if self.player:hasTreasure("LuminousPearl") and ((self.player:getHeadSkillList(true, false, false):contains(skill) and not self.player:hasShownGeneral1())
		or (self.player:getDeputySkillList(true, false, false):contains(skill) and not self.player:hasShownGeneral2())) then show = "" end

	local has_Crossbow = self:getCardsNum("Crossbow") > 0
	if (has_Crossbow or self:hasCrossbowEffect()) and #self.enemies > 0 and self.player:getCardCount(true) >= 4 then
		local zcards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(zcards, true)
		for _, zcard in ipairs(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("Slash", zcard, self.player)
			and not isCard("BefriendAttacking", zcard, self.player) and not isCard("AllianceFeast", zcard, self.player)
			and (self.player:getOffensiveHorse() or zcard:isKindOf("OffensiveHorse") or not has_Crossbow)
			and not zcard:isKindOf("Crossbow") and not self.player:isJilei(zcard)
			then--别把杀和连弩弃了
				table.insert(unpreferedCards, zcard:getEffectiveId())
				if #unpreferedCards >= self.player:getMaxHp() and not unlimited then break end
			end
		end
		if (#unpreferedCards > self.player:getMaxHp() or not self.player:ownSkill("zhiheng")) and self.player:getTreasure() then
			table.removeOne(unpreferedCards, self.player:getTreasure():getEffectiveId())
		end
		if #unpreferedCards > 0 then
			if #unpreferedCards > self.player:getMaxHp() then
				use.card = sgs.Card_Parse("@ZhihengCard=" .. table.concat(unpreferedCards, "+") .. "&zhiheng")
			else
				use.card = sgs.Card_Parse("@ZhihengCard=" .. table.concat(unpreferedCards, "+") .. show)
			end
			return
		end
	end

	if self.player:getHp() < 3 then
		--local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic  = false, false, false
		local keep_weapon
		local zcards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(zcards, true)
		for _, zcard in ipairs(zcards) do
			local friend_need = false
			if all_dis then
				local c_table = {}
				table.insert(c_table, zcard)
				local acard, afriend = self:getCardNeedPlayer(c_table, self.friends_noself)
				if acard and afriend then friend_need = true end
			end
			if (not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player)
			and not isCard("BefriendAttacking", zcard, self.player) and not isCard("AllianceFeast", zcard, self.player)) or friend_need then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) and not(self.player:getTreasure() or zcard:isKindOf("Treasure")) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 or (all_dis and (#unpreferedCards < (unlimited and self.player:getCardCount(true) or self.player:getMaxHp()))) then
		local use_slash_num = 0
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end

	end

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local has_equip = {}
	if self.player:hasSkills(sgs.lose_equip_skill) then
		for index = #unpreferedCards, 1, -1 do
			if self.player:hasEquip(sgs.Sanguosha:getCard(unpreferedCards[index])) then
				table.insert(has_equip, unpreferedCards[index])
				if #has_equip > 1 then
					table.removeOne(unpreferedCards, unpreferedCards[index])
				end
			end
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then
			if #use_cards < self.player:getMaxHp() and not unlimited then
				table.insert(use_cards, unpreferedCards[index])
			end
			if unlimited then
				table.insert(use_cards, unpreferedCards[index])
			end
		end
	end
	if (#use_cards > self.player:getMaxHp() or not self.player:ownSkill("zhiheng")) and self.player:getTreasure() then
		table.removeOne(use_cards, self.player:getTreasure():getEffectiveId())
	end
	if #use_cards > 0 then
		if #unpreferedCards > self.player:getMaxHp() then
			use.card = sgs.Card_Parse("@ZhihengCard=" .. table.concat(use_cards, "+") .. "&zhiheng")
		else
			use.card = sgs.Card_Parse("@ZhihengCard=" .. table.concat(use_cards, "+") .. show)
		end
	end
end

sgs.ai_use_value.ZhihengCard = 9
sgs.ai_use_priority.ZhihengCard = 2.61
sgs.dynamic_value.benefit.ZhihengCard = true

function sgs.ai_cardneed.zhiheng(to, card)
	return not card:isKindOf("Jink")
end

--甘宁
local qixi_skill = {}
qixi_skill.name = "qixi"
table.insert(sgs.ai_skills, qixi_skill)
qixi_skill.getTurnUseCard = function(self, inclusive)

	local cards = {}
	if self.player:hasSkills(sgs.lose_equip_skill) and not self.player:getEquips():isEmpty() then
		for _, c in sgs.qlist(self.player:getEquips()) do
			if c:isBlack() then table.insert(cards, c) end
		end
		if #cards > 0 then
			self:sortByUseValue(cards, true)
			local black_card = cards[1]
			local suit = black_card:getSuitString()
			local number = black_card:getNumberString()
			local card_id = black_card:getEffectiveId()
			local card_str = ("dismantlement:qixi[%s:%s]=%d%s"):format(suit, number, card_id, "&qixi")
			local dismantlement = sgs.Card_Parse(card_str)

			assert(dismantlement)

			return dismantlement
		end
	end

	local allcard = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		allcard:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(allcard)
	self:sortByUseValue(cards, true)

	local has_weapon = false
	local black_card
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			elseif card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			elseif card:isKindOf("Slash") then
				local dummy_use = {isDummy = true}
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			elseif card:isKindOf("TrickCard") and self:getUseValue(card) > sgs.ai_use_value.Dismantlement then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if not self:willShowForAttack() then
				shouldUse = false
			end

			if self.player:hasSkill("duannian") and self.player:isLastHandCard(card) and sgs.ai_skill_invoke.duannian(self) then
				shouldUse = false--配合周夷
			end

			if shouldUse then
				black_card = card
				break
			end

		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("dismantlement:qixi[%s:%s]=%d%s"):format(suit, number, card_id, "&qixi")
		local dismantlement = sgs.Card_Parse(card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.qixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.ai_suit_priority.qixi= "diamond|heart|club|spade"

function sgs.ai_cardneed.qixi(to, card)
	return card:isBlack()
end

--吕蒙
sgs.ai_skill_invoke.keji = function(self, data)--如何主动触发？
	--sgs.isAnjiang(self.player)
	if not self.player:hasShownSkill("keji") then
		if self.player:hasShownOneGeneral() then
			if self:getOverflow() <= 0 then return false end
		else
			if not self:willShowForDefence() then
				if self:getOverflow() <= 0 then return false end
				if not self.player:hasSkill("tianxiang") then return false end
			end
		end
	end
	local erzhang = sgs.findPlayerByShownSkillName("guzheng")
	local guzheng = (erzhang and erzhang:isAlive() and self:isFriend(erzhang) and erzhang:objectName()~=self.player:objectName())
	if guzheng and self:getOverflow() > 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards, true)
		local card, friend = self:getCardNeedPlayer(cards, {erzhang})
		if card and friend then return false end
	end
	return true
end

sgs.ai_skill_invoke.mouduan = function(self, data)
	if self.player:hasShownOneGeneral() then return true end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:getMoveCardorTarget(p, ".") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.mouduan = function(self, _targets, max_num, min_num)

	self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".") then
				return {friend, self:getMoveCardorTarget(friend, "target")}
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".") then
				return {friend, self:getMoveCardorTarget(friend, "target")}
			end
		end

		local targets = {}
		for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
			if not self.player:isFriendWith(enemy) and self:getMoveCardorTarget(enemy, "." ,"e") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return {targets[#targets], self:getMoveCardorTarget(targets[#targets], "target")}
		end

		if self.player:hasEquip() and self.player:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(self.player, ".") then
			return {self.player, self:getMoveCardorTarget(self.player, "target" ,"e")}
		end

		local friends = {}--没有敌人则简单转移队友装备
		for _, friend in ipairs(self.friends) do
			if self:getMoveCardorTarget(friend, "." ,"e") then
				table.insert(friends, friend)
			end
		end

		if #friends > 0 then
			self:sort(friends, "hp", true)
			return {friends[#friends], self:getMoveCardorTarget(friends[#friends], "target")}
		end

	return {}
end

sgs.ai_skill_transfercardchosen.mouduan = function(self, targets, equipArea, judgingArea)
	return self:getMoveCardorTarget(targets:first(), "card")
end
--[[
sgs.ai_skill_use["@@mouduan_move"] = function(self, prompt, method)
	self:updatePlayers()
	if prompt ~= "@mouduan-move" then
		Global_room:writeToConsole("not_mouduan_move:"..prompt)
		return "."
	end
	local MDCard = "@MouduanMoveCard=.&->"

		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".") then
				self.mouduancard = self:getMoveCardorTarget(friend, "card")
				return MDCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".") then
				self.mouduancard = self:getMoveCardorTarget(friend, "card")
				return MDCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
			end
		end

		local targets = {}
		for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
			if not self.player:isFriendWith(enemy) and self:getMoveCardorTarget(enemy, "." ,"e") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			self.mouduancard = self:getMoveCardorTarget(targets[#targets], "card")
			return MDCard .. targets[#targets]:objectName() .. "+" .. self:getMoveCardorTarget(targets[#targets], "target"):objectName()
		end

		if self.player:hasEquip() and self.player:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(self.player, ".") then
			self.mouduancard = self:getMoveCardorTarget(self.player, "card","e")
			return MDCard .. self.player:objectName() .. "+" .. self:getMoveCardorTarget(self.player, "target" ,"e"):objectName()
		end

		local friends = {}--没有敌人则简单转移队友装备
		for _, friend in ipairs(self.friends) do
			if self:getMoveCardorTarget(friend, "." ,"e") then
				table.insert(friends, friend)
			end
		end

		if #friends > 0 then
			self:sort(friends, "hp", true)
			self.mouduancard = self:getMoveCardorTarget(friends[#friends], "card")
			return MDCard .. friends[#friends]:objectName() .. "+" .. self:getMoveCardorTarget(friends[#friends], "target"):objectName()
		end
	if not self.player:hasShownOneGeneral() then
		Global_room:writeToConsole("mouduan_move_nil:"..prompt)
	end
	return "."
end

sgs.ai_skill_askforag["mouduan"] = function(self, card_ids)
	return self.mouduancard:getId()
end
--]]
--黄盖
local function getKurouCard(self, not_slash)
    local card_id
    local hold_crossbow = (self:getCardsNum("Slash") > 1)
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local lightning = self:getCard("Lightning")

    if self:needToThrowArmor() then
        card_id = self.player:getArmor():getId()
    elseif self.player:getHandcardNum() > self.player:getHp() then
        if lightning and not self:willUseLightning(lightning) then
            card_id = lightning:getEffectiveId()
        else
            for _, acard in ipairs(cards) do
                if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                    and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
                    and not (acard:isKindOf("Slash") and not_slash) then
                    card_id = acard:getEffectiveId()
                    break
                end
            end
        end
    elseif not self.player:getEquips():isEmpty() then
        local player = self.player
        if player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
        elseif player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 3
                and not (player:getWeapon():isKindOf("Crossbow") and hold_crossbow) then card_id = player:getWeapon():getId()
        elseif player:getArmor() and self:evaluateArmor(self.player:getArmor()) < 2 then card_id = player:getArmor():getId()
        end
    end
    if not card_id then
        if lightning and not self:willUseLightning(lightning) then
            card_id = lightning:getEffectiveId()
        else
            for _, acard in ipairs(cards) do
                if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                    and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
                    and not (acard:isKindOf("Slash") and not_slash) then
                    card_id = acard:getEffectiveId()
                    break
                end
            end
        end
    end
    return card_id
end

local kurou_skill = {}
kurou_skill.name = "kurou"
table.insert(sgs.ai_skills, kurou_skill)
kurou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("KurouCard") or not self.player:canDiscard(self.player, "he") then return end
	self.player:setFlags("-Kurou_toDie")
	sgs.ai_use_priority.KurouCard = 6.8
	local id = getKurouCard(self)
	if not id then return end
	local kuroucard = sgs.Card_Parse("@KurouCard=" .. id .. "&kurou")

	if not self:willShowForAttack() then return nil end

	if self.player:getHp() < 1 then return nil end
	if self.player:getMark("Global_TurnCount") < 2 and not self.player:hasShownOneGeneral() then return nil end

	if (self.player:getHp() > 3 and self:getOverflow(self.player, false) < 2)
	or (self.player:getHp() > 2 and self:getOverflow(self.player, false) < -1)
	or (self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1) then
		return kuroucard
	end

	if self.player:hasSkill("jieyin") and not self.player:hasUsed("JieyinCard") and not self.player:isWounded() then
		local jiyou = self:getWoundedFriend(true)
		if jiyou then
			return kuroucard
		end
	end

	if (self.player:getHp() > 2 and self.player:getLostHp() <= 1 and self.player:hasSkill("xiaoji") and self.player:getCards("e"):length() > 1) then
		return kuroucard
	end

	local slash = sgs.cloneCard("slash")
	if self:hasCrossbowEffect(self.player) then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasShownOneGeneral() then
				if self.player:canSlash(enemy, nil, true) and self:slashIsEffective(slash, enemy)
					and not (enemy:hasShownSkill("kongcheng") and enemy:isKongcheng())
					and not (enemy:hasShownSkills("fankui") and self.player:hasWeapon("Crossbow"))
					and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(slash, enemy) and self.player:getHp() > 1 then
					return kuroucard
				end
			end
		end
	end
	if self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1 then
		return kuroucard
	end

	if type(self.kept) == "table" and #self.kept > 0 then
		local hcards = sgs.QList2Table(self.player:getHandcards())
		for _, c in ipairs(self.kept) do
			hcards = self:resetCards(hcards, c)
		end
		for _, c in ipairs(self.kept) do
			if isCard("Peach", c, self.player) or isCard("Analeptic", c, self.player) then
				sgs.ai_use_priority.KurouCard = 0
				return kuroucard
			end
		end
	end

	--Suicide by Kurou 是否需要调整？
	if self:SuicidebyKurou() then
		self.room:setPlayerFlag(self.player, "Kurou_toDie")
		sgs.ai_use_priority.KurouCard = 0
		return kuroucard
	end
end

function SmartAI:SuicidebyKurou()
	local nextplayer = self.player:getNextAlive()
	local to_death = false
	if self.player:getMark("GlobalBattleRoyalMode") > 0 or self.player:isLord() then
		return false
	end
	if self.player:getHp() == 1 and self:getCardsNum("Armor") == 0 and self:getCardsNum("Jink") == 0 and self:getKingdomCount() > 1 then
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng() and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasShownSkill("jieyin") and self.player:isMale() then return end
				--if nextplayer:hasShownSkill("qingnang") then return end
			end
		end
		if not self:isFriend(nextplayer) and (not self:willSkipPlayPhase(nextplayer) or nextplayer:hasShownSkill("shensu")) then
			to_death = true
		end
		if to_death then
			local caopi = sgs.findPlayerByShownSkillName("xingshang")
			if caopi and self:isEnemy(caopi) and self.player:getHandcardNum() > 3 then
				to_death = false
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if self.player:getHandcardNum() > 3 then
			local erzhang = sgs.findPlayerByShownSkillName("guzheng")
			if erzhang and self:isFriend(erzhang) then to_death = false end
			if erzhang and self:isEnemy(erzhang) then to_death = true end
		end
		if to_death then
			for _, friend in ipairs(self.friends_noself) do
				if getKnownCard(friend, self.player, "Peach", true, "he") > 0 then
					to_death = false
					break
				end
			end
		end
	end
	return to_death
end

sgs.ai_skill_use_func.KurouCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.KurouCard = 6.8

--周瑜
sgs.ai_skill_invoke.yingzi_zhouyu = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	--[[
	if self.player:hasFlag("haoshi") then
		local invoke = self.player:getTag("haoshi_yingzi_zhouyu"):toBool()
		self.player:removeTag("haoshi_yingzi_zhouyu")
		if not invoke then return false end
		local extra = self.player:getMark("haoshi_num")
		if self.player:hasShownOneGeneral() and not self.player:hasShownSkill("yingzi_zhouyu") and self.player:getMark("HalfMaxHpLeft") > 0 then
			extra = extra + 1
		end
		if self.player:hasShownOneGeneral() and not self.player:isWounded()	and not self.player:hasShownSkill("yingzi_zhouyu") and player:getMark("CompanionEffect") > 0 then
			extra = extra + 2
		end
		if self.player:getHandcardNum() + extra <= 1 or self.haoshi_target then
			self.player:setMark("haoshi_num", extra)
			return true
		end
		return false
	end
	--]]
	return true
end

local fanjian_skill = {}
fanjian_skill.name = "fanjian"
table.insert(sgs.ai_skills, fanjian_skill)
fanjian_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then return nil end
	if self.player:isKongcheng() then return nil end
	if self.player:hasUsed("FanjianCard") then return nil end
	return sgs.Card_Parse("@FanjianCard=.&fanjian")
end

sgs.ai_skill_use_func.FanjianCard = function(fjCard, use, self)
local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    self:sort(self.enemies, "defense")

    if self:getCardsNum("Slash") > 0 then
        local slash = self:getCard("Slash")
        local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
        self:useCardSlash(slash, dummy_use)
        if dummy_use.card and dummy_use.to:length() > 0 then
            sgs.ai_use_priority.FanjianCard = sgs.ai_use_priority.Slash + 0.15
            local target = dummy_use.to:first()
            if self:isEnemy(target) and sgs.card_lack[target:objectName()]["Jink"] ~= 1 and target:getMark("yijue") == 0
                and not target:isKongcheng() and (self:getOverflow() > 0 or target:getHandcardNum() > 2)
                and not (self.player:hasSkill("liegong") and target:getHp() >= self.player:getHp())
            then
                if target:hasSkill("qingguo") then
                    for _, card in ipairs(cards) do
                        if self:getUseValue(card) < 6 and card:isBlack() and not isCard("Peach", card, target) and not isCard("Analeptic", card, target) then
                            use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                            if use.to then use.to:append(target) end
                            return
                        end
                    end
                end
                for _, card in ipairs(cards) do
                    if self:getUseValue(card) < 6 and card:getSuit() == sgs.Card_Diamond and not isCard("Peach", card, target) and not isCard("Analeptic", card, target) then
                        use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                        if use.to then use.to:append(target) end
                        return
                    end
                end
            end
        end
    end
    --@todu反间护心镜
	local fanjian_card = nil
	local rich_enemie = nil
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 and not card:isKindOf("Peach") and not card:isKindOf("Analeptic") then
			fanjian_card = card
			break
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local v = enemy:getHandcardNum() - 4 + enemy:getEquips():length()
		if self:isWeak(enemy) then v = v + 2 end
		if self:needToThrowArmor(enemy) then v = v - 2 end
		if enemy:hasSkills(sgs.lose_equip_skill) then v = v - 2 end
		if self:doNotDiscard(enemy, "he") then v = v - 2 end
		if v >= 0 then rich_enemie = enemy break end
	end
    if self:getOverflow() <= 0 and not (fanjian_card and rich_enemie) then return end--尽量反间
    sgs.ai_use_priority.FanjianCard = 0.2
    local suit_table = { "spade", "club", "heart", "diamond" }
    local equip_val_table = { 1.2, 1.5, 0.5, 1, 1.3 }
    for _, enemy in ipairs(self.enemies) do
        if enemy:getHandcardNum() > 2 and not enemy:isRemoved() and (not enemy:hasSkill("hongfa") or enemy:getPile("heavenly_army"):isEmpty())
			and not (enemy:hasSkill("lirang") and #self.enemies > 1) then
            local max_suit_num, max_suit = 0, {}
            for i = 0, 3, 1 do
                local suit_num = getKnownCard(enemy, self.player, suit_table[i + 1])
                for j = 0, 4, 1 do
                    if enemy:getEquip(j) and enemy:getEquip(j):getSuit() == i then
                        local val = equip_val_table[j + 1]
                        if j == 1 and self:needToThrowArmor(enemy) then val = -0.5
                        else
                            if enemy:hasSkills(sgs.lose_equip_skill) then val = val / 8 end
                            if enemy:getEquip(j):getEffectiveId() == self:getValuableCard(enemy) then val = val * 1.1 end
                            if enemy:getEquip(j):getEffectiveId() == self:getDangerousCard(enemy) then val = val * 1.1 end
                        end
                        suit_num = suit_num + j
                    end
                end
                if suit_num > max_suit_num then
                    max_suit_num = suit_num
                    max_suit = { i }
                elseif suit_num == max_suit_num then
                    table.insert(max_suit, i)
                end
            end
            if max_suit_num == 0 then
				if self:getOverflow() <= 0 then--没有已知牌时
					local v = enemy:getHandcardNum() - 4 + enemy:getEquips():length()
					if self:isWeak(enemy) then v = v + 2 end
					if self:needToThrowArmor(enemy) then v = v - 2 end
					if enemy:hasSkills(sgs.lose_equip_skill) then v = v - 2 end
					if self:doNotDiscard(enemy, "he") then v = v - 2 end
					if v <= 0 then continue end
					local msg = string.format("%s/%s[Visiblecards]:", enemy:getActualGeneral1Name(), enemy:getActualGeneral2Name())
					local cards = sgs.QList2Table(enemy:getHandcards())
					for _, card in ipairs(cards) do
						if sgs.cardIsVisible(card, enemy, self.player) then
							msg = msg .. card:getClassName() ..", "
						end
					end
					Global_room:writeToConsole(msg)
				end
				max_suit = {}
                local suit_value = { 1, 1, 1.3, 1.5 }
                for _, skill in ipairs(sgs.QList2Table(enemy:getVisibleSkillList(true))) do
                    if sgs[skill:objectName() .. "_suit_value"] then
                        for i = 1, 4, 1 do
                            local v = sgs[skill:objectName() .. "_suit_value"][suit_table[i]]
                            if v then suit_value[i] = suit_value[i] + v end
                        end
                    end
                end
                local max_suit_val = 0
                for i = 0, 3, 1 do
                    local suit_val = suit_value[i + 1]
                    if suit_val > max_suit_val then
                        max_suit_val = suit_val
                        max_suit = { i }
                    elseif suit_val == max_suit_val then
                        table.insert(max_suit, i)
                    end
                end
            end
            for _, card in ipairs(cards) do
                if self:getUseValue(card) < 6 and table.contains(max_suit, card:getSuit()) and not isCard("Peach", card, enemy) and not isCard("Analeptic", card, enemy) then
                    use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
            if getCardsNum("Peach", enemy, self.player) < 2 then
                for _, card in ipairs(cards) do
                    if self:getUseValue(card) < 6 and not self:isValuableCard(card) and not isCard("Peach", card, enemy) and not isCard("Analeptic", card, enemy) then
                        use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                        if use.to then use.to:append(enemy) end
                        return
                    end
                end
            end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend:hasSkill("hongyan") then
            for _, card in ipairs(cards) do
                if self:getUseValue(card) < 6 and card:getSuit() == sgs.Card_Spade then
                    use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
        if friend:hasSkill("zhaxiang") and not self:isWeak(friend) and not (friend:getHp() == 2 and friend:hasSkill("chanyuan")) then
            for _, card in ipairs(cards) do
                if self:getUseValue(card) < 6 then
                    use.card = sgs.Card_Parse("@FanjianCard=" .. card:getEffectiveId() .. "&fanjian")
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end
end

sgs.ai_card_intention.FanjianCard = 70

sgs.ai_skill_invoke.fanjian_show = function(self, data)--弃置全部闪时判断是否会被杀？
	if self.player:isRemoved() then
		return false
	end
	if self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty() then--君张角
		return false
	  end
    local suit = self.player:getMark("FanjianSuit")
    local count = 0
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:getSuit() == suit then
			if self.player:getHp() == 1 and (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
				return false
			end
            count = count + 1
            if self:isValuableCard(card) then count = count + 0.5 end
        end
    end
    local equip_val_table = { 2, 2.5, 1, 1.5, 2.2 }
    for i = 0, 4, 1 do
        if self.player:getEquip(i) and self.player:getEquip(i):getSuit() == suit then
            if i == 1 and self:needToThrowArmor() then
                count = count - 1
            else
                count = equip_val_table[i + 1]
                if self.player:hasSkills(sgs.lose_equip_skill) then count = count + 0.5 end
            end
        end
    end
	if count <= 1 then return true end
	if self:getCardsNum("Peach") >= 1 and self.player:getMark("GlobalBattleRoyalMode") == 0 and not self:willSkipPlayPhase() then return false end
	if self.player:getHandcardNum() <= 3 or self:isWeak() then return true end
    return count / self.player:getCardCount(true) <= 0.6
end

--大乔
local guose_skill = {}
guose_skill.name = "guose"
table.insert(sgs.ai_skills, guose_skill)
guose_skill.getTurnUseCard = function(self, inclusive)

	local cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	  end
	cards=sgs.QList2Table(cards)

--[[修改了木马的使用价值
	if self.player:hasTreasure("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then
		table.removeOne(cards,sgs.Sanguosha:getCard(self.player:getTreasure():getEffectiveId()))
	end
]]
	local card
	self:sortByUseValue(cards, true)
	local has_weapon, has_armor = false, false

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Weapon") and not (acard:getSuit() == sgs.Card_Diamond) then has_weapon=true end
	end

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Armor") and not (acard:getSuit() == sgs.Card_Diamond) then has_armor=true end
	end

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Diamond) and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive) then
			local shouldUse=true

			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0 then shouldUse = false
				end
			end

			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_weapon then shouldUse = false
				end
			end

			if not self:willShowForAttack() then
				shouldUse = false
			end

			if self.player:hasSkill("duannian") and self.player:isLastHandCard(acard) and sgs.ai_skill_invoke.duannian(self) then
				shouldUse = false--配合周夷
			end

			if shouldUse then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("indulgence:guose[diamond:%s]=%d&guose"):format(number, card_id)
	local indulgence = sgs.Card_Parse(card_str)
	assert(indulgence)
	return indulgence
end

function sgs.ai_cardneed.guose(to, card)
	return card:getSuit() == sgs.Card_Diamond
end

sgs.ai_suit_priority.guose= "club|spade|heart|diamond"


sgs.ai_skill_use["@@liuli"] = function(self, prompt, method)
	local others = self.room:getOtherPlayers(self.player)
	others = sgs.QList2Table(others)

	local use = self.player:getTag("liuli-use"):toCardUse()
	local list = self.player:property("liuli_available_targets"):toString():split("+")

	local slash = use.card
    local source = use.from

	local nature = sgs.Slash_Natures[slash:getClassName()]

	if ((not self:willShowForDefence() and self:getCardsNum("Jink") > 1) or (not self:willShowForMasochism() and self:getCardsNum("Jink") == 0))
		and source:getMark("drank") == 0 then
			return "."
	end

	local doLiuli = function(who)
		if not self:isFriend(who) and who:hasShownSkill("leiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end
		if not self:isFriend(who) and self:isFriend(source, who) and source:hasShownSkill("zhiman")
			and (who:containsTrick("supply_shortage") or who:containsTrick("indulgence"))then
			return "."
		end							 

		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and self.player:canSlash(who) then
				if self:isFriend(who) and (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "."
				else
					return "@LiuliCard="..card:getEffectiveId().."&liuli->"..who:objectName()
				end
			end
		end

		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)
		self:sortByKeepValue(ecards)
		if self.player:hasTreasure("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then
			local recover_num = 0
			for _,id in sgs.qlist(self.player:getPile("wooden_ox")) do
				if sgs.Sanguosha:getCard(id):isKindOf("Peach") or (sgs.Sanguosha:getCard(id):isKindOf("Analeptic") and self.player:getHp() == 1) then
					recover_num = recover_num + 1
				end
			end
			if self:hasHeavySlashDamage(source, slash, self.player, true) <= recover_num and self:isFriend(who) then
				table.removeOne(ecards,self.player:getTreasure())
			end
		end
		for _, card in ipairs(ecards) do
			local range_fix = 0
			if card:isKindOf("Weapon") then range_fix = range_fix + sgs.weapon_range[card:getClassName()] - self.player:getAttackRange(false) end
			if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
			if not self.player:isCardLimited(card, method) and self.player:canSlash(who, nil, true, range_fix) then
				return "@LiuliCard=" .. card:getEffectiveId() .. "&liuli->" .. who:objectName()
			end
		end
		return "."
	end

	local isJinkEffected
	for _, jink in ipairs(self:getCards("Jink")) do
		if self.room:isJinkEffected(self.player, jink) then isJinkEffected = true break end
	end

	local liuli = {}

	if not self:damageIsEffective(self.player, nature, source) then liuli[2] = "."
	elseif self:needToLoseHp(self.player, source, true) then liuli[2] = "."
	elseif self:needDamagedEffects(self.player, source, true) then liuli[2] = "." end

	self:sort(others, "defense")
	for _, player in ipairs(others) do
		if not (source and source:objectName() == player:objectName()) then
			if self:isEnemy(player) then
				if not (source and source:objectName() == player:objectName()) then
					if self:slashIsEffective(slash, player, false, source) then
						if not self:needDamagedEffects(player, source, true) then
							if self:hasHeavySlashDamage(source, slash, player) then
								if not source or self:isFriend(source, player) then
									local ret = doLiuli(player)
									if ret ~= "." then return ret end
								elseif not liuli[1] then
									local ret = doLiuli(player)
									if ret ~= "." then liuli[1] = ret end
								end
							elseif not liuli[5] then
								local ret = doLiuli(player)
								if ret ~= "." then liuli[5] = ret end
							end
						elseif not liuli[8] then
							local ret = doLiuli(player)
							if ret ~= "." then liuli[8] = ret end
						end
					elseif not liuli[6] then
						local ret = doLiuli(player)
						if ret ~= "." then liuli[6] = ret end
					end
				end
			elseif self:isFriend(player) then
				if not (source and source:objectName() == player:objectName()) then
					if self:slashIsEffective(slash, player, source) then
						if self:findLeijiTarget(player, 50, source) then
							local ret = doLiuli(player)
							if ret ~= "." then liuli[3] = ret end
						elseif not self:hasHeavySlashDamage(source, slash, player) then
							if self:needDamagedEffects(player, source, true) or self:needToLoseHp(player, source, true, true) then
								local ret = doLiuli(player)
								if ret ~= "." then liuli[4] = ret end
							end
						elseif self:isWeak() and (not isJinkEffected or self:canHit(self.player, source)) then
							if getCardsNum("Jink", player, self.player) >= 1 then
								local ret = doLiuli(player)
								if ret ~= "." then liuli[10] = ret end
							elseif not self:isWeak(player) or not self.player:hasShownOneGeneral() then
								local ret = doLiuli(player)
								if ret ~= "." then liuli[11] = ret end
							end
						end
					else
						local ret = doLiuli(player)
						if ret ~= "." then liuli[7] = ret end
					end
				end
			else
				local ret = doLiuli(player)
				if ret ~= "." then liuli[9] = ret end
			end
		end
	end

	local ret = "."
	local i = 99
	for k, str in pairs(liuli) do
		if k < i then
			i = k
			ret = str
		end
	end

	return ret
end


function sgs.ai_slash_prohibit.liuli(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriendsNoself(from)) do
		if to:canSlash(friend, card) and self:slashIsEffective(card, friend, from) and self:canHit(friend, from) then return true end
	end
end

function sgs.ai_cardneed.liuli(to, card)
	return to:getCardCount(true) <= 2
end

sgs.guose_suit_value = { diamond = 3.9 }


function SmartAI:getWoundedFriend(maleOnly)
	self:sort(self.friends, "hp")
	local list1 = {}	-- need help
	local list2 = {}	-- do not need help
	local addToList = function(p,index)
		if ( (not maleOnly) or (maleOnly and p:isMale()) ) and p:isWounded() and p:canRecover() then
			table.insert(index ==1 and list1 or list2, p)
		end
	end

	local getCmpHp = function(p)
		local hp = p:getHp()
		if p:isLord() and self:isWeak(p) then hp = hp - 10 end
		--if p:objectName() == self.player:objectName() and self:isWeak(p) and p:hasShownSkill("qingnang") then hp = hp - 5 end
		if p:hasShownSkill("buqu") and p:getPile("scars"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("scars"):length()) end
		if p:hasShownSkills("rende|kuanggu") and p:getHp() >= 2 then hp = hp + 5 end
		return hp
	end


	local cmp = function (a ,b)
		if getCmpHp(a) == getCmpHp(b) then
			return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
		else
			return getCmpHp(a) < getCmpHp(b)
		end
	end

	for _, friend in ipairs(self.friends) do
		if friend:isLord() then
			if self:needToLoseHp(friend, nil, nil, true, true) then
				addToList(friend, 2)
			else
				addToList(friend, 1)
			end
		else
			if self:needToLoseHp(friend, nil, nil, nil, true) or (friend:hasShownSkills("rende|kuanggu|zaiqi") and friend:getHp() >= 2) then
				addToList(friend, 2)
			else
				addToList(friend, 1)
			end
		end
	end
	table.sort(list1, cmp)
	table.sort(list2, cmp)
	return list1, list2
end

--陆逊
sgs.ai_skill_invoke.qianxun = true

local duoshi_skill = {}
duoshi_skill.name = "duoshi"
table.insert(sgs.ai_skills, duoshi_skill)
duoshi_skill.getTurnUseCard = function(self, inclusive)
	local DuoTime = 1
	if self.player:hasSkills("hongyan|yingzi_zhouyu|yingzi_sunce|yingzi_flamemap|haoshi|haoshi_flamemap") then
		DuoTime = 2
	end
	for _, player in ipairs(self.friends) do
		if player:hasShownSkills("xiaoji|xuanlue|diaodu") then--
			DuoTime = 2
			break
		end
	end
	--if self.player:hasSkills("xiaoji|xuanlue|diaodu") then
	if self.player:hasSkills("xiaoji+xuanlue|xiaoji+diaodu|xuanlue+diaodu") then--枭姬回合内收益降低了
		DuoTime = 2
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") then
				DuoTime = DuoTime + 1
			end
		  end
	end
	if self.player:getHandcardNum() > 4 then
		DuoTime = DuoTime + 1
	end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	
	local to_use = 0
	for _, c in ipairs(cards) do
		local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
		self:useCardByClassName(c,dummy_use)
		if dummy_use.card then
			to_use = to_use + 1
		end
	end
	
	local over_flow = math.max(self:getOverflow() - to_use, 0)
	
	if self.player:usedTimes("ViewAsSkill_duoshiCard") >= DuoTime or over_flow < 0 then return end
	if self.player:usedTimes("ViewAsSkill_duoshiCard") >= 4 then return end

	if sgs.turncount <= 1 and #self.friends_noself == 0 and not self:isWeak() and over_flow <= 0 then return end
	local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) >= 4.5 and card:isAvailable(self.player) then
			local dummy_use = {isDummy = true}
			if not card:targetFixed() then dummy_use.to = sgs.SPlayerList() end
			if card:isKindOf("EquipCard") then
				self:useEquipCard(card, dummy_use)
			else
				self:useCardByClassName(card, dummy_use)
			end
			if dummy_use.card and self:getUsePriority(card) >= 2.8 then
				return
			end
		end
	end

	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange  and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashes = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashes) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return end
			end
		end
	end

	local red_card
	if self.player:getHandcardNum() <= 1 then return end
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isRed() then
			local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.AwaitExhausted and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end



			if not self:willShowForDefence() then
				local sunshangxiang = false
				if self.player:hasSkill("xiaoji") and self.player:hasEquip() then
					sunshangxiang = true
				end
				for _, player in ipairs(self.friends) do
					if player:hasShownSkill("xiaoji") and player:hasEquip() then
						sunshangxiang = true
						break
					end
				end
				if not sunshangxiang then
					shouldUse = false
				end
			end

			if shouldUse and not card:isKindOf("Peach") then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = string.format("await_exhausted:duoshi[%s:%d]=%d&duoshi",red_card:getSuitString(), red_card:getNumber(), red_card:getEffectiveId())
		local await = sgs.Card_Parse(card_str)
		assert(await)
		return await
	end
end

--孙尚香
local jieyin_skill = {}
jieyin_skill.name = "jieyin"
table.insert(sgs.ai_skills, jieyin_skill)
jieyin_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 2 then return nil end
	if self.player:hasUsed("JieyinCard") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local first, second
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			local dummy_use = {isDummy = true}
			self:useTrickCard(card, dummy_use)
			if not dummy_use.card then
				if not first then first = card:getEffectiveId()
				elseif first and not second then second = card:getEffectiveId()
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_TypeEquip and (not self:isValuableCard(card) or self.player:isWounded()) then
			if not first then first = card:getEffectiveId()
			elseif first and first ~= card:getEffectiveId() and not second then second = card:getEffectiveId()
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("@JieyinCard=%d+%d%s"):format(first, second, "&jieyin")
	assert(card_str)
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.JieyinCard = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(true)
	table.removeOne(arr1, self.player)
	table.removeOne(arr2, self.player)
	local target = nil

	local num = 0
	repeat
		if #arr1 > 0 and (self:isWeak(arr1[1]) or self:isWeak() or self:getOverflow() >= 1) then
			target = arr1[1]
			break
		end
		if #arr2 > 0 and self:isWeak() then
			target = arr2[1]
			break
		end
		num = num + 1
		Global_room:writeToConsole("jieyin死循环？" ..num)
	until true

	if not target and self:isWeak() and self:getOverflow() >= 2 and (self.role == "careerist" or self.player:getMark("GlobalBattleRoyalMode") > 0) then
		local others = self.room:getOtherPlayers(self.player)
		for _, other in sgs.qlist(others) do
			if other:isWounded() and other:isMale() and not other:hasShownSkills(sgs.masochism_skill) then
				target = other
				self.player:setFlags("jieyin_isenemy_" .. other:objectName())
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.JieyinCard = 2.8

sgs.ai_card_intention.JieyinCard = function(self, card, from, tos)
	if not from:hasFlag("jieyin_isenemy_"..tos[1]:objectName()) then
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.dynamic_value.benefit.JieyinCard = true

sgs.ai_skill_invoke.xiaoji = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence()) then
		return false
	end
	return true
end

sgs.xiaoji_keep_value = {
	Weapon = 4.9,
	Armor = 5,
	OffensiveHorse = 4.8,
	DefensiveHorse = 4.9,
	SixDragons = 5,
	Treasure = 5
}

sgs.ai_cardneed.xiaoji = sgs.ai_cardneed.equip

--孙坚
sgs.ai_skill_playerchosen.yinghun_sunjian = function(self, targets)
	--Global_room:writeToConsole("进入英魂")
	local x = self.player:getLostHp()
	local n = math.abs(x - 1)
	self:updatePlayers()
	if #self.friends_noself == 0 and (x == 1 or #self.enemies == 0) then
		return nil
	end

	local yinghun_friend = nil
	local AssistTarget = self:AssistTarget()

	if x == 1 then
		self:sort(self.friends_noself, "handcard", true)
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasShownSkills(sgs.lose_equip_skill) and friend:hasEquip() then
				yinghun_friend = friend
				break
			end
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				if friend:hasShownSkill("tuntian") then
					yinghun_friend = friend
					break
				end
			end
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				if self:needToThrowArmor(friend) then
					yinghun_friend = friend
					break
				end
			end
		end

		if not yinghun_friend and AssistTarget and AssistTarget:getCardCount(true) > 0 and not self:needKongcheng(AssistTarget, true) then
			yinghun_friend = AssistTarget
		end

		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				if friend:getCardCount(true) > 0 then
					yinghun_friend = friend
					break
				end
			end
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				yinghun_friend = friend
				break
			end
		end
	elseif #self.friends > 1 then
		self:sort(self.friends_noself, "handcard")
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasShownSkills(sgs.lose_equip_skill) and friend:hasEquip() and not self:willSkipPlayPhase(friend) then
				yinghun_friend = friend
				break
			end
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				if friend:hasShownSkill("tuntian") and not self:willSkipPlayPhase(friend) then
					yinghun_friend = friend
					break
				end
			end
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				if self:needToThrowArmor(friend) and not self:willSkipPlayPhase(friend) then
					yinghun_friend = friend
					break
				end
			end
		end
		if not yinghun_friend and #self.enemies > 0 then
			local weakf = false
			if self:isWeak() and self.player:getHp() < 2 and self:getAllPeachNum() < 1 then
				weakf = true
			end
			if not weakf then
				for _, friend in ipairs(self.friends_noself) do
					if self:isWeak(friend) and not self:willSkipPlayPhase(friend) then
						weakf = true
						break
					end
				end
			end
			if not weakf then
				self:sort(self.enemies)
				for _, enemy in ipairs(self.enemies) do
					if enemy:getCardCount(true) == n
						and not self:doNotDiscard(enemy, "he", true, n) then
						self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if enemy:getCardCount(true) >= n
						and not self:doNotDiscard(enemy, "he", true, n)
						and enemy:hasShownSkills(sgs.cardneed_skill) then
						self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
						return enemy
					end
				end
			end
		end

		if not yinghun_friend and AssistTarget and not self:needKongcheng(AssistTarget, true) then
			yinghun_friend = AssistTarget
		end
		if not yinghun_friend then
			yinghun_friend = self:findPlayerToDraw(false, n)
		end
		if not yinghun_friend then
			for _, friend in ipairs(self.friends_noself) do
				yinghun_friend = friend
				break
			end
		end
	end
	if yinghun_friend then
		self.yinghunchoice = x > 0 and "dxt1" or "d1tx"
		Global_room:writeToConsole("英魂队友:"..sgs.Sanguosha:translate(yinghun_friend:getGeneralName()).."/"..sgs.Sanguosha:translate(yinghun_friend:getGeneral2Name()))
		return yinghun_friend
	end
	if x ~= 1 and #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getCardCount(true) <= n and (self:getDangerousCard(enemy) or self:getValuableCard(enemy))
				and not self:doNotDiscard(enemy, "he", true, n) then
				self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
				return enemy
			end
		end
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getCardCount(true) >= n and not self:doNotDiscard(enemy, "he", true, n) then
				self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
				return enemy
			end
		end
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude()
				and not (enemy:hasShownSkills(sgs.lose_equip_skill) and enemy:hasEquip())
				and not (self:needToThrowArmor(enemy) and (x == 2 or x == 0))
				and not enemy:hasShownSkill("tuntian") then
				self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
				return enemy
			end
		end
	end
	if x ~= 1 then
		for _, enemy in sgs.qlist(targets) do
			if not self:isFriend(enemy) and not enemy:isNude()
				and not (enemy:hasShownSkills(sgs.lose_equip_skill) and enemy:hasEquip())
				and not (self:needToThrowArmor(enemy) and (x == 2 or x == 0))
				and not (enemy:hasShownSkill("tuntian") and x < 3 and enemy:getCardCount(true) < 2) then
				self.yinghunchoice = x > 0 and "d1tx" or "dxt1"
				return enemy
			end
		end
	end

	return nil
end

sgs.ai_skill_choice.yinghun_sunjian = function(self, choices)
	return self.yinghunchoice
end

sgs.ai_playerchosen_intention.yinghun_sunjian = function(self, from, to)
	if from:getLostHp() > 1 then return end
	local intention = -80
	sgs.updateIntention(from, to, intention)
end

sgs.ai_choicemade_filter.skillChoice.yinghun_sunjian = function(self, player, promptlist)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("YinghunTarget") then
			to = p
			break
		end
	end
	local choice = promptlist[#promptlist]
	local intention = (choice == "dxt1") and -80 or 80
	sgs.updateIntention(player, to, intention)
end

--小乔
sgs.ai_skill_use["@@tianxiang"] = function(self, data, method)
	if not method then method = sgs.Card_MethodDiscard end

	local card_tianxiang
	local card_id
	local dmg

	if data == "@tianxiang-card" then
		dmg = self.player:getTag("TianxiangDamage"):toDamage()
	else
		dmg = data
	end

	if not dmg then self.room:writeToConsole(debug.traceback()) return "." end
	if not self:willShowForMasochism() and dmg.damage <= 1 then return "." end
	
	if self.player:hasFlag("tianxiang1used") and self.player:hasFlag("tianxiang2used") then
		return "."
	elseif self.player:hasFlag("tianxiang2used") then
		self.tianxiang_choice = 1
	elseif self.player:hasFlag("tianxiang1used") then
		self.tianxiang_choice = 2
	else
		self.tianxiang_choice = nil
	end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, method) and (card:getSuit() == sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade)) then
			card_tianxiang = card
			break
		end
	end

	if not card_tianxiang then return "." end
	card_id = card_tianxiang:getId()

--[[
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if (enemy:getHp() <= dmg.damage  and enemy:getLostHp() + dmg.damage < 3 and enemy:isAlive()) and not (enemy:hasShownSkill("kuanggu") and dmg.from and dmg.from:objectName() == enemy:objectName()) then
			if enemy:hasShownSkill("jijiu") and (enemy:getHandcardNum() > 2 or getKnownCard(enemy, self.player, "red", true) > 0) then continue end
			if (enemy:getHandcardNum() <= 2 or enemy:ha~=sShownSkills("guose|leiji|ganglie|qingguo|kongcheng") or enemy:containsTrick("indulgence"))
				and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature) then
				return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. enemy:objectName()
			end
		end
	end

	local newDamageStruct = dmg
	for _, friend in ipairs(self.friends_noself) do
		newDamageStruct.to = friend
		if not self:damageIsEffective_(newDamageStruct) then
			return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. friend:objectName()
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if (friend:getLostHp() + dmg.damage > 1 and friend:isAlive()) then
			if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(friend, dmg.from, dmg.nature, dmg.damage, dmg.card) then
			elseif friend:getHp() >= 2 and dmg.damage < 2
					and (friend:hasShownSkills("yiji|shuangxiong|zaiqi|jianxiong|fangzhu")
						or self:needDamagedEffects(friend, dmg.from or self.room:getCurrent())
						or self:needToLoseHp(friend)
						or (friend:getHandcardNum() < 3 and friend:hasShownSkill("rende"))) then
				return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. friend:objectName()
			elseif HasBuquEffect(friend) then return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. friend:objectName() end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if (enemy:getLostHp() <= 1 or dmg.damage > 1) and enemy:getLostHp() + dmg.damage < 4 and enemy:isAlive() and not (enemy:hasShownSkill("kuanggu")
			and dmg.from and dmg.from:objectName() == enemy:objectName()) then
			if (enemy:getHandcardNum() <= 2)
				or enemy:containsTrick("indulgence") or enemy:hasShownSkills("guose|leiji|ganglie|qingguo|kongcheng")
				and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature) then
				return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. enemy:objectName() end
		end
	end

	for i = #self.enemies, 1, -1 do
		local enemy = self.enemies[i]
		if not enemy:isWounded() and not enemy:hasShownSkills(sgs.masochism_skill) and enemy:isAlive()
			and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature) and self:isWeak() and not (enemy:hasShownSkill("kuanggu") and dmg.from and dmg.from:objectName() == enemy:objectName()) then
			return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. enemy:objectName()
		end
	end
]]--										 
	
	--[[
	--处理早了,应该是对方是否视为桃		   
	if isCard("Peach", card_tianxiang, self.player) and not self.player:hasFlag("tianxiang1used") then
		self.tianxiang_choice = 1
	elseif not self.player:hasFlag("tianxiang2used") then
		self.tianxiang_choice = 2
	end
	--]]
	--压敌方血线
	self:sort(self.enemies, "hp")
	local spare_target = nil
	for _, enemy in ipairs(self.enemies) do
		if not self.tianxiang_choice then
			if self.player:hasSkill("lirang") and not self.player:hasFlag("tianxiang2used") then
				self.tianxiang_choice = 2
			elseif isCard("Peach", card_tianxiang, enemy) and not self.player:hasFlag("tianxiang1used") then
				self.tianxiang_choice = 1
			elseif enemy:getLostHp() == 0 and sgs.ais[enemy:objectName()]:getKeepValue(card_tianxiang) < 3.24 then
				--self:getUseValue(card_tianxiang)
				--sgs.ai_use_value.KnownBoth = 5
				--sgs.ai_keep_value.KnownBoth = 3.24
				self.tianxiang_choice = 1
			else
				self.tianxiang_choice = 2
			end
		end
		if self.tianxiang_choice == 1 then
			if not self:damageIsEffective(enemy, dmg.nature, dmg.from or self.room:getCurrent()) then continue end
			if enemy:getLostHp() + dmg.damage > 2 then
				if enemy:getHp() - dmg.damage > 0 then continue end
				local peach_num = getCardsNum("Peach", enemy, self.player)
				if not self.player:hasSkill("wansha") then
					for _, enemy_f in ipairs(self:getFriendsNoself(enemy)) do
						peach_num = peach_num + getCardsNum("Peach", enemy_f, self.player)
					end
				end
				if peach_num + getCardsNum("Analeptic", enemy, self.player) > 0 then continue end
			else
				if dmg.from and dmg.from:hasSkill("kuanggu") and dmg.from:objectName() == enemy:objectName() then continue end
			end
		elseif self.tianxiang_choice == 2 and not self.player:hasSkill("lirang") then
			if enemy:hasSkill("hongfa") and not enemy:getPile("heavenly_army"):isEmpty() then continue end
			if isCard("Peach", card_tianxiang, enemy) and not self:willSkipPlayPhase(enemy) then continue end
		end
		if enemy:isAlive() and not enemy:isRemoved() then
			if enemy:getHp() <=2 or enemy:getHandcardNum() <= 2 or self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature) then
				if enemy:hasShownSkill("jijiu") and enemy:getHp() <= 2 and self.tianxiang_choice == 1 then
					if not self.player:hasFlag("tianxiang2used") then
						self.tianxiang_choice = 2
					else continue end
				end
				return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. enemy:objectName()
			end
		end
	end

	if not card_tianxiang:isKindOf("Peach") and not self.player:hasFlag("tianxiang1used") then
		for _, friend in ipairs(self.friends_noself) do
			if (friend:getLostHp() + dmg.damage > 1 and friend:isAlive()) then
				if friend:getHp() >= 2 and (friend:hasShownSkills("shuangxiong|zaiqi|"..sgs.masochism_skill) or self:needToLoseHp(friend)) then
					self.tianxiang_choice = 1
					return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. friend:objectName()
				elseif HasBuquEffect(friend) or friend:isRemoved() then
					self.tianxiang_choice = 1
					return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. friend:objectName()
				end
			end
		end
	end

	if self:getCardsNum({"Peach", "Analeptic"}) == 0 or self.player:getMark("GlobalBattleRoyalMode") > 0 or dmg.damage > 1 or dmg.damage >= self.player:getHp() then
		local targets = self.enemies
		if #targets == 0 then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not self:isFriend(p) then table.insert(targets, p) end
			end
		end
		if #targets == 0 and dmg.from then table.insert(targets, dmg.from) end
		if #targets == 0 then table.insert(targets, self.player:getNextAlive()) end
		if #targets > 0 then
			self:sort(targets, "hp")
			targets = sgs.reverse(targets)
			local target = targets[1]
			if self:isEnemy(target) then 
				if not self.tianxiang_choice then
					if self.player:hasSkill("lirang") then
						self.tianxiang_choice = 2
					elseif isCard("Peach", card_tianxiang, target) then
						self.tianxiang_choice = 1
					elseif target:getLostHp() == 0 and sgs.ais[target:objectName()]:getKeepValue(card_tianxiang) < 3.24 then
						self.tianxiang_choice = 1
					else
						self.tianxiang_choice = 2
					end
				end
			elseif not self.player:hasFlag("tianxiang1used") then
				self.tianxiang_choice = 1
			end
			if self.tianxiang_choice == 1 then
				if not self:damageIsEffective(target, dmg.nature, dmg.from or self.room:getCurrent()) then return "." end
				if target:getLostHp() + dmg.damage > 2 then
					if target:getHp() - dmg.damage > 0 then return "." end
					local peach_num = getCardsNum("Peach", target, self.player)
					if not self.player:hasSkill("wansha") then
						for _, enemy_f in ipairs(self:getFriendsNoself(target)) do
							peach_num = peach_num + getCardsNum("Peach", enemy_f, self.player)
						end
					end
					if peach_num + getCardsNum("Analeptic", target, self.player) > 0 then return "." end
				else
					if dmg.from and dmg.from:hasSkill("kuanggu") and dmg.from:objectName() == target:objectName() then return "." end
				end
			elseif self.tianxiang_choice == 2 and not self.player:hasSkill("lirang") then
				if target:hasSkill("hongfa") and not target:getPile("heavenly_army"):isEmpty() then return "." end
				if isCard("Peach", card_tianxiang, target) and not self:willSkipPlayPhase(target) then return "." end
			end
			return "@TianxiangCard=" .. card_id .. "&tianxiang->" .. target:objectName()
		end
	end

	return "."
end

sgs.ai_skill_choice.tianxiang = function(self, choices, data)
	choices = choices:split("+")
	--"damage%from:%1%to:%2","losehp%to:%1%log:%2"
	if #choices > 1 then 
		Global_room:writeToConsole("天香选择:"..self.tianxiang_choice)
	end
	return choices[self.tianxiang_choice]
end

sgs.ai_card_intention.TianxiangCard = function(self, card, from, tos)
	local to = tos[1]
	if self:needDamagedEffects(to) or self:needToLoseHp(to) then return end
	local intention = 10
	if HasBuquEffect(to) then intention = 0
	elseif (to:getHp() >= 2 and to:hasShownSkills("yiji|shuangxiong|zaiqi|yinghun_sunjian|yinghun_sunce|jianxiong|fangzhu"))
		or to:getHandcardNum() < 3 and to:hasShownSkill("rende") then
		intention = -10
	end
	sgs.updateIntention(from, to, intention)
end

function sgs.ai_slash_prohibit.tianxiang(self, from, to)
	if self:isFriend(to, from) then return false end
	if from:hasShownSkills("tieqi|tieqi_xh|yinbing") then return false end
	return self:cantbeHurt(to, from)
end

sgs.tianxiang_suit_value = {
	heart = 4.9
}

function sgs.ai_cardneed.tianxiang(to, card, self)
	return (card:getSuit() == sgs.Card_Heart or (to:hasShownSkill("hongyan") and card:getSuit() == sgs.Card_Spade))
		and (getKnownCard(to, self.player, "heart", false) + getKnownCard(to, self.player, "spade", false)) < 2
end

sgs.ai_suit_priority.hongyan= "club|diamond|spade|heart"

--太史慈
local tianyi_skill = {}
tianyi_skill.name = "tianyi"
table.insert(sgs.ai_skills, tianyi_skill)
tianyi_skill.getTurnUseCard = function(self)
	if self:willShowForAttack() and not self.player:hasUsed("TianyiCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@TianyiCard=.&tianyi") end
end

sgs.ai_skill_use_func.TianyiCard = function(TYCard, use, self)
	if #self.enemies < 1 then return end
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxNumberCard(self.player, cards)
	if not max_card then return end
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point + 3, 13) end
	local slashcount = self:getCardsNum("Slash")
	if isCard("Slash", max_card, self.player) then
		slashcount = slashcount - 1
	end
	local double_slash = slashcount + self.player:getSlashCount() > 1
		and (self:hasCrossbowEffect() or self.player:hasFlag("kurouInvoked"))

	local zhugeliang = sgs.findPlayerByShownSkillName("kongcheng")

	local slash = self:getCard("Slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("TianyiSuccess")
	self.player:setFlags("slashNoDistanceLimit")
	if slash then self:useBasicCard(slash, dummy_use) end
	self.player:setFlags("-slashNoDistanceLimit")
	self.player:setFlags("-TianyiSuccess")

	sgs.ai_use_priority.TianyiCard = (slashcount >= 1 and dummy_use.card) and 7.2 or 1.2
	if slashcount > 0 and slash and dummy_use.card then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasShownSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() then
				local enemy_max_card = self:getMaxNumberCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if enemy_max_card and enemy:hasShownSkill("yingyang") then enemy_max_point = math.min(enemy_max_point + 3, 13) end
				if self:getKnownNum(enemy) == enemy:getHandcardNum() and max_point > enemy_max_point then
					self.tianyi_card = max_card:getId()
					use.card = TYCard
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end

		self:sort(self.friends_noself, "handcard", true)
		if dummy_use.to:length() > 1 and double_slash then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:isKongcheng() then
					local friend_min_card = self:getMinNumberCard(friend)
					local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
					if friend:hasShownSkill("yingyang") then friend_min_point = math.max(1, friend_min_point - 3) end
					if max_point > friend_min_point then
						local hcards = sgs.QList2Table(self.player:getHandcards())
						self:sortByUseValue(hcards,true)
						for _, c in ipairs(hcards) do
						  if c:getNumber() + (self.player:hasShownSkill("yingyang") and 3 or 0) > friend_min_point then
							self.tianyi_card = c:getId()
							use.card = TYCard
							if use.to then
								use.to:append(friend)
								return
							end
						  end
						end
					end
				end
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasShownSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() then
				local enemy_max_card = self:getMaxNumberCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if enemy_max_card and enemy:hasShownSkill("yingyang") then enemy_max_point = math.min(enemy_max_point + 3, 13) end
				if max_point > enemy_max_point or max_point > 10 then
					self.tianyi_card = max_card:getId()
					use.card = TYCard
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end

		if dummy_use.to:length() > 1 then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:isKongcheng() then
					local friend_min_card = self:getMinNumberCard(friend)
					local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
					if friend:hasShownSkill("yingyang") then friend_min_point = math.max(1, friend_min_point - 3) end
					if max_point > friend_min_point then
						local hcards = sgs.QList2Table(self.player:getHandcards())
						self:sortByUseValue(hcards,true)
						for _, c in ipairs(hcards) do
						  if c:getNumber() + (self.player:hasShownSkill("yingyang") and 3 or 0) > friend_min_point then
							self.tianyi_card = c:getId()
							use.card = TYCard
							if use.to then
								use.to:append(friend)
								return
							end
						  end
						end
					end
				end
			end
		end

		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and zhugeliang:objectName() ~= self.player:objectName() then
			if max_point >= 7 then
				self.tianyi_card = max_card:getId()
				use.card = TYCard
				if use.to then use.to:append(zhugeliang) end
				return
			end
		end

		if dummy_use.to:length() > 1 then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:isKongcheng() then
					if max_point >= 7 then
						self.tianyi_card = max_card:getId()
						use.card = TYCard
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end

	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1
		and zhugeliang:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.player, zhugeliang) >= 1 then
		if isCard("Jink", cards[1], self.player) and self:getCardsNum("Jink") == 1 then return end
		self.tianyi_card = cards[1]:getId()
		use.card = TYCard
		if use.to then use.to:append(zhugeliang) end
		return
	end

	if self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:doNotDiscard(enemy, "h", true) and not enemy:isKongcheng() then
				self.tianyi_card = cards[1]:getId()
				use.card = TYCard
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.tianyi(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxNumberCard()
	return self:isFriend(requestor) and self:getMinNumberCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_cardneed.tianyi = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		if sgs.cardIsVisible(c, to, self.player) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	end
end

sgs.ai_choicemade_filter.pindian.tianyi = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:objectName() == promptlist[5] then
			target = p
			break
		end
	end
	local target_str = sgs.Sanguosha:translate(target:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(target:getActualGeneral2Name())
	local player_card_number = sgs.Sanguosha:getCard(promptlist[4]):getNumber()
	local target_card_number = sgs.Sanguosha:getCard(promptlist[6]):getNumber()
	Global_room:writeToConsole("天义目标:"..target_str.."("..player_card_number..":"..target_card_number..")")
	if target_card_number >= 10 then
		sgs.updateIntention(target, player, 20*(14 - target_card_number))--目标,太史慈
	elseif target_card_number <= 4 then
		sgs.updateIntention(target, player, 20*(4-target_card_number))--目标,太史慈
	end
end

sgs.ai_card_intention.TianyiCard = 0
sgs.dynamic_value.control_card.TianyiCard = true

sgs.ai_use_value.TianyiCard = 8.5

--周泰
sgs.ai_skill_askforag.buqu = function(self, card_ids)
	for i, card_id in ipairs(card_ids) do
		for j, card_id2 in ipairs(card_ids) do
			if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
				return card_id
			end
		end
	end

	return card_ids[1]
end

function sgs.ai_skill_invoke.buqu(self, data)
	return true
end

sgs.ai_skill_invoke.fenji = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then return false end
	local target = self.room:getCurrent()
	if self:isFriend(target) then
		if self:isWeak() and target:objectName() ~= self.player:objectName() then return false end
		if target:hasShownSkill("kongcheng") and target:isKongcheng() and target:getHp() >= 2 then return false end
		return true
	end
	return false
end

--鲁肃
sgs.ai_skill_invoke.haoshi = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then return false end
	self.haoshi_target = nil
	self.haoshi_flamemap_target = nil
	local haoshi_flamemap = false
	if self.player:getLord() then
		local sunquan = self.room:getLord(self.player:getKingdom())
		local n = sunquan:getPile("flame_map"):length()
		if n >= 3 then haoshi_flamemap = true end
	end
	local extra = 0
	local draw_skills = { ["yingzi_flamemap"] = 1, ["yingzi_zhouyu"] = 1, ["yingzi_sunce"] = 1 }
	for skill_name, n in pairs(draw_skills) do
		if self.player:hasSkill(skill_name) then
			local skill = sgs.Sanguosha:getSkill(skill_name)
			if skill and skill:getFrequency() == sgs.Skill_Compulsory then
				extra = extra + n
			--[[else
				self.player:removeTag("haoshi_" .. skill_name)]]--
			end
		end
	end
	--[[
	if self.player:hasShownOneGeneral() and self.player:ownSkill("haoshi") and not self.player:hasShownSkill("haoshi") and self.player:getMark("HalfMaxHpLeft") > 0 then
		extra = extra + 1
	end
	if self.player:hasShownOneGeneral() and not self.player:isWounded()	and self.player:ownSkill("haoshi") and not self.player:hasShownSkill("haoshi") and self.player:getMark("CompanionEffect") > 0 then
		extra = extra + 2
	end
	]]
	if self.player:hasSkill("congcha") then
		local congcha_draw = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then
				congcha_draw = false
				break
			end
		end
		if congcha_draw then
		extra = extra + 2
		end
	end
	if self.player:hasTreasure("JadeSeal") then
		extra = extra + 1
	end
	if self.player:getHandcardNum() + extra <= 1 then return true end

	local function find_haoshi_target()
		local otherPlayers = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(otherPlayers, "handcard")
		local leastNum = otherPlayers[1]:getHandcardNum()
		local flamemap_leastNum = leastNum + math.floor((self.player:getHandcardNum() + extra) / 2)
		if haoshi_flamemap and #otherPlayers > 1 then
			flamemap_leastNum = math.min(flamemap_leastNum,otherPlayers[2]:getHandcardNum())
		end
		self:sort(self.friends_noself, "handcard")
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() == leastNum and friend:isAlive() and self:isFriendWith(friend) then
				self.haoshi_target = friend
			elseif haoshi_flamemap and friend:getHandcardNum() == flamemap_leastNum and friend:isAlive() and self:isFriendWith(friend) then
				self.haoshi_flamemap_target = friend
			end
		end
		if not self.haoshi_target then
			for _, friend in ipairs(self.friends_noself) do
				if friend:getHandcardNum() == leastNum and friend:isAlive() then
					self.haoshi_target = friend
				elseif haoshi_flamemap and friend:getHandcardNum() == flamemap_leastNum and friend:isAlive() and not self.haoshi_flamemap_target then
					self.haoshi_flamemap_target = friend
				end
			end
		end
		if self.haoshi_target then return true end
	end

	if not find_haoshi_target() then return false end
	--[[
	for skill_name, n in pairs(draw_skills) do
		if self.player:hasSkill(skill_name) then
			local skill = sgs.Sanguosha:getSkill(skill_name)
			if skill and skill:getFrequency() ~= sgs.Skill_Compulsory then
				if find_haoshi_target(extra + n) then
					extra = extra + n
					self.player:setTag("haoshi_" .. skill_name, sgs.QVariant(true))
				else
					self.player:removeTag("haoshi_" .. skill_name)
				end
			end
		end
	end
	self.player:setMark("haoshi_num", extra)
	]]--现在界英姿变为锁定技
	return true
end

sgs.ai_skill_use["@@haoshi_give!"] = function(self, prompt)
	local target = self.haoshi_target
	if not self.haoshi_target or self.haoshi_target:isDead() then
		local otherPlayers = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(otherPlayers, "handcard")
		local leastNum = otherPlayers[1]:getHandcardNum()
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() == leastNum and self:isFriendWith(friend) and friend:isAlive() then
				target = friend
				break
			end
		end
		if not target then
			for _, friend in ipairs(self.friends_noself) do
				if friend:getHandcardNum() == leastNum and friend:isAlive() then
					target = friend
					break
				end
			end
		end
		if not target then
			target = otherPlayers[1]
		end
	end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card_ids = {}
	for i = 1, math.floor(#cards / 2) do
		table.insert(card_ids, cards[i]:getEffectiveId())
	end
	self.haoshi_target = nil
	self.haoshi_flamemap_target = nil
	return "@HaoshiCard=" .. table.concat(card_ids, "+") .. "&haoshi->" .. target:objectName()
end

sgs.ai_card_intention.HaoshiCard = -80

function sgs.ai_cardneed.haoshi(to, card, self)
	return not self:willSkipDrawPhase(to)
end

local dimeng_skill = {}
dimeng_skill.name = "dimeng"
table.insert(sgs.ai_skills, dimeng_skill)
dimeng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("DimengCard") then return end
	local card = sgs.Card_Parse("@DimengCard=.&dimeng")
	return card
end

local dimeng_discard = function(self, discard_num, cards)
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:getUseValue(card) >= 6 then return 3
		elseif self.player:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

--要求：mycards是经过sortByKeepValue排序的--
function DimengIsWorth(self, friend, enemy, mycards, myequips)
	local e_hand1, e_hand2 = enemy:getHandcardNum(), enemy:getHandcardNum() - self:getLeastHandcardNum(enemy)
	local f_hand1, f_hand2 = friend:getHandcardNum(), friend:getHandcardNum() - self:getLeastHandcardNum(friend)
	local e_peach, f_peach = getCardsNum("Peach", enemy, self.player), getCardsNum("Peach", friend, self.player)
	--getCardsNum会计算急救的红装备和珠联璧合……
	local jijiu_revise = 0
	if friend:hasShownSkill("jijiu") then
		jijiu_revise = self:getSuitNum("red", false, friend) - self:getSuitNum("red", false, enemy)
	end
	if e_hand1 < f_hand1 then
		return false
	elseif e_hand2 <= f_hand2 and e_peach <= f_peach + jijiu_revise then
		return false
	elseif e_peach < f_peach + jijiu_revise and e_peach < 1 then
		return false
	elseif e_hand1 == f_hand1 and e_hand1 > 0 then
		return friend:hasShownSkill("tuntian")
	end
	local cardNum = #mycards
	local delt = e_hand1 - f_hand1 --assert: delt>0
	if delt > cardNum then
		return false
	end
	if #myequips > 0 and self.player:hasSkill("xiaoji") then return true end
	--now e_hand1>f_hand1 and delt<=cardNum
	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt / 2)
	for i = 1, delt, 1 do
		local card = mycards[i]
		local keepValue = self:getKeepValue(card)
		if keepValue > 4 then
			soKeep = soKeep + 1
		end
		local useValue = self:getUseValue(card)
		if useValue >= 6 then
			soUse = soUse + 1
		end
	end
	if soKeep > marker then
		return false
	end
	if soUse > marker then
		return false
	end
	return true
end


sgs.ai_skill_use_func.DimengCard = function(card,use,self)
	local mycards = {}
	local myequips = {}
	local keepaslash
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end
	for _, c in sgs.qlist(self.player:getEquips()) do
		if not self.player:isJilei(c) then
			table.insert(mycards, c)
			table.insert(myequips, c)
		end
	end
	if #mycards == 0 then return end
	self:sortByKeepValue(mycards)

	self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		table.insert(friends, player)
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = a:getHandcardNum() - self:getLeastHandcardNum(a)
		local y = b:getHandcardNum() - self:getLeastHandcardNum(b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	self:sort(self.enemies, "defense")

	for _, enemy in ipairs(self.enemies) do
		local e_hand = enemy:getHandcardNum()
		for _, friend in ipairs(friends) do
			local f_hand = friend:getHandcardNum()
			if DimengIsWorth(self, friend, enemy, mycards, myequips) and (e_hand > 0 or f_hand > 0) then
				if e_hand == f_hand then
					use.card = card
				else
					local discard_num = math.abs(e_hand - f_hand)
					local discards = dimeng_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = sgs.Card_Parse("@DimengCard=" .. table.concat(discards, "+") .."&dimeng") end
				end
				if use.to then
					use.to:append(enemy)
					use.to:append(friend)
				end
				return
			end
		end
	end
	--缔盟队友
	if #friends < 2 then return end
	
	local to_dis = 1
	if self:getOverflow() > 0 then
		to_dis = math.min(self.player:getCardCount(true), self:getOverflow() + 1)
	end
	
	for _, friend_a in ipairs(friends) do
		local fa_hand = friend_a:getHandcardNum()
		for _, friend_b in ipairs(friends) do
			if friend_b:objectName() == friend_a:objectName() then continue end
			local fb_hand = friend_b:getHandcardNum()
			local discard_num = math.abs(fa_hand - fb_hand)
			if (self:isWeak(friend_a) and fb_hand <= 3) or (self:isWeak(friend_b) and fa_hand <= 3)
				or discard_num > to_dis or (fa_hand == 0 and fb_hand == 0) then continue end
			if fa_hand == fb_hand then
				use.card = card
			else
				local discards = dimeng_discard(self, discard_num, mycards)
				if #discards > 0 then use.card = sgs.Card_Parse("@DimengCard=" .. table.concat(discards, "+") .."&dimeng") end
			end
			if use.to then
				use.to:append(friend_a)
				use.to:append(friend_b)
			end
			return
		end
	end
end

sgs.ai_card_intention.DimengCard = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getHandcardNum() < b:getHandcardNum()
	end
	table.sort(to, compare_func)
	if to[1]:getHandcardNum() < to[2]:getHandcardNum() then
		sgs.updateIntention(from, to[1], -80)
	end
end

sgs.ai_use_value.DimengCard = 3.5
--待劳2.8,远交9.28,顺4.3
--sgs.ai_use_priority.DimengCard = 2.8
sgs.ai_use_priority.DimengCard = 4.3

sgs.dynamic_value.control_card.DimengCard = true

--张昭＆张纮
local zhijian_skill = {}
zhijian_skill.name = "zhijian"
table.insert(sgs.ai_skills, zhijian_skill)
zhijian_skill.getTurnUseCard = function(self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end

	return sgs.Card_Parse("@ZhijianCard=.&zhijian")
end

sgs.ai_skill_use_func.ZhijianCard = function(zjcard, use, self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if card:isKindOf("Crossbow") and self:getCardsNum("Slash") > 2 then
			elseif not self:getSameEquip(card) then
			else
				table.insert(equips, card)
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end

	if #equips == 0 then return end

	local select_equip, target
	for _, equip in ipairs(equips) do
		for _, friend in ipairs(self.friends_noself) do--找需要装备的队友
			if not self:getSameEquip(equip, friend) and friend:hasShownSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _, friend in ipairs(self.friends_noself) do
			if not self:getSameEquip(equip, friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end

	if not target then return end
	if use.to then use.to:append(target) end
	local zhijian = sgs.Card_Parse("@ZhijianCard=" .. select_equip:getId() .. "&zhijian")
	assert(zhijian)
	use.card = zhijian
end

sgs.ai_card_intention.ZhijianCard = -80
sgs.ai_use_priority.ZhijianCard = sgs.ai_use_priority.RendeCard + 0.1
sgs.ai_cardneed.zhijian = sgs.ai_cardneed.equip

local function getBestHp(player)
	local arr = {ganlu = 1, yinghun_sunjian = 2, hunshang = 1}
	for skill, dec in pairs(arr) do
		if player:hasSkill(skill) then
			return math.max( (player:isLord() and 3 or 2) ,player:getMaxHp() - dec)
		end
	end
	return player:getMaxHp()
end

sgs.ai_skill_exchange.guzheng = function(self, pattern, max_num, min_num, expand_pile)
	local card_ids = self.player:property("guzheng_allCards"):toString():split("+")
	local who = self.room:getCurrent()

	if not self.player:hasShownOneGeneral() then
		if not (self:willShowForAttack() or self:willShowForDefence()) and #card_ids < 3  then
			return {}
		end
	end
	local flag
	if not self.player:hasShownOneGeneral() then
		flag = self.player:inHeadSkills("guzheng") and "h" or "d"
	end

	local invoke = (self:isFriend(who) and not (who:hasSkill("kongcheng") and who:isKongcheng()))
					or (#card_ids >= 2 and #card_ids <= 3 and not who:hasShownSkills(sgs.cardneed_skill)) or #card_ids > 3
					or (self:isEnemy(who) and who:hasSkill("kongcheng") and who:isKongcheng())
	if not invoke then return {} end

	local cards, except_Equip, except_Key , all = {}, {}, {}, {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(all, card)
		if self.player:hasSkill("zhijian") and not card:isKindOf("EquipCard") then
			table.insert(except_Equip, card)
		end
		if not card:isKindOf("Peach") and not card:isKindOf("Jink") and not card:isKindOf("Analeptic") and
			not card:isKindOf("Nullification") and not (card:isKindOf("EquipCard") and self.player:hasSkill("zhijian")) then
			table.insert(except_Key, card)
		end
		table.insert(cards, card)
	end

	if self:isFriend(who) then
		local peach_num = 0
		local peach, jink, analeptic, slash
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") then
				peach = card:getEffectiveId()
				peach_num = peach_num + 1
			end
			if card:isKindOf("Jink") then jink = card:getEffectiveId() end
			if card:isKindOf("Analeptic") then analeptic = card:getEffectiveId() end
			if card:isKindOf("Slash") then slash = card:getEffectiveId() end
		end
		if peach then
			if peach_num > 1
				or (self:getCardsNum("Peach") >= self.player:getMaxCards())
				or (who:getHp() < getBestHp(who) and who:getHp() < self.player:getHp()) then
					return {peach}
			end
		end
		if self:isWeak(who) and (jink or analeptic) then
			if jink then
				return {jink}
			elseif analeptic then
				return {analeptic}
			end
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") then
				for _, askill in sgs.qlist(who:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback)=="function" and callback(who, card, self) then
						return {card:getEffectiveId()}
					end
				end
			end
		end

		if jink or analeptic or slash then
			if jink then
				return {jink}
			elseif analeptic then
				return {analeptic}
			elseif slash then
				return {slash}
			end
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") and not card:isKindOf("Peach") then
				return {card:getEffectiveId()}
			end
		end

		local card, friend = self:getCardNeedPlayer(all, {who})
		if card and friend then
			return {card:getEffectiveId()}
		else
			return {all[1]:getEffectiveId()}
		end

	else

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and self.player:hasSkill("zhijian") then
				local Cant_Zhijian = true
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) then
						Cant_Zhijian = false
					end
				end
				if Cant_Zhijian then
					return {card:getEffectiveId()}
				end
			end
		end

		local new_cards = (#except_Key > 0 and except_Key) or (#except_Equip > 0 and except_Equip) or cards

		self:sortByKeepValue(new_cards)
		local valueless, slash
		for _, card in ipairs (new_cards) do
			if card:isKindOf("Lightning") and not who:hasShownSkills(sgs.wizard_harm_skill) then
				return {card:getEffectiveId()}
			end

			if card:isKindOf("Slash") then slash = card:getEffectiveId() end

			if not valueless and not card:isKindOf("Peach") then
				for _, askill in sgs.qlist(who:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if (type(callback)=="function" and not callback(who, card, self)) or not callback then
						valueless = card:getEffectiveId()
						break
					end
				end
			end
		end

		if slash or valueless then
			if slash then
				return {slash}
			elseif valueless then
				return {valueless}
			end
		end

		return {new_cards[1]:getEffectiveId()}
	end
end

sgs.ai_skill_choice.guzheng = function(self, choices, data)
	return "yes"
end

--丁奉
local fenxun_skill = {}
fenxun_skill.name = "fenxun"
table.insert(sgs.ai_skills, fenxun_skill)
fenxun_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then return end
	if self.player:hasUsed("FenxunCard") then return end
	if self.player:isNude() then return end
	return sgs.Card_Parse("@FenxunCard=.&fenxun")
end

sgs.ai_skill_use_func.FenxunCard = function(card, use, self)
	local shouldUse = false
	local slashCard
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	for _, slash in ipairs(self:getCards("Slash")) do
		dummy_use.to = sgs.SPlayerList()
		dummy_use.card = nil
		self:useCardSlash(slash, dummy_use)
		if self:slashIsAvailable(self.player, slash) and dummy_use.to:length() < #self.enemies
		and dummy_use.to:length() <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash) then
			shouldUse = true
			slashCard = slash
		end
	end

	if #self.enemies == 0 then return end
	if not self:slashIsAvailable() then return end
	if not shouldUse then return end
	if not slashCard then return end

	local cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:getEffectiveId() ~= slashCard:getEffectiveId() then table.insert(cards, c) end
	end
	self:sortByUseValue(cards,true)
	local card_id
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	end
	if not card_id then
		for _, c in ipairs(cards) do
			if c:isKindOf("Lightning") and not isCard("Peach", c, self.player) and not self:willUseLightning(c) then
				card_id = c:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		for _, c in ipairs(cards) do
			if not isCard("Peach", c, self.player)
				and (c:isKindOf("AmazingGrace") or c:isKindOf("GodSalvation") and not self:willUseGodSalvation(c)) then
				card_id = c:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		local isWeak
		for _, to in sgs.qlist(dummy_use.to) do
			if self:isWeak(to) and to:getHp() <= 1 then isWeak = true break end
		end

		for _, c in ipairs(cards) do
			if (not isCard("Peach", c, self.player) or self:getCardsNum("Peach") > 1)
				and (not isCard("Jink", c, self.player) or self:getCardsNum("Jink") > 1 or isWeak)
				and not (self.player:getWeapon() and self.player:getWeapon():getEffectiveId() == c:getEffectiveId())
				and not (self.player:getOffensiveHorse() and self.player:getOffensiveHorse():getEffectiveId() == c:getEffectiveId()) then
				card_id = c:getEffectiveId()
			end
		end
	end

	local target
	self:sort(self.enemies, "defense")
	if dummy_use.to:isEmpty() then
		target = self.enemies[1]
	end
	for _, enemy in ipairs(self.enemies) do
		if not target and not dummy_use.to:contains(enemy) then
			if self.player:distanceTo(enemy) > 1 and not self:slashProhibit(slashCard, enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
				target = enemy
				break
			end
		end
	end

	if card_id and target then
		use.card = sgs.Card_Parse("@FenxunCard=" .. card_id .. "&fenxun")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value.FenxunCard = 3
sgs.ai_use_priority.FenxunCard = 8
sgs.ai_card_intention.FenxunCard = 50

sgs.ai_skill_playerchosen.duanbing = function(self, targets)
	if not self:willShowForAttack() then return nil end
	local target = sgs.ai_skill_playerchosen.slash_extra_targets(self, targets)
	return target
end
