
-- @example Implementation of el farol model.
-- It is based on Brian Arthur's paper available at
-- http://www.santafe.edu/~wbarthur/Papers/El_Farol.html
-- @arg N Number of agents.
-- @arg K number of strategies an agent have (if it is one the agents will never change their strategies).
-- @arg MAX Maximum number of people in the bar.
-- @arg LAST_TURNS number of turns 

N = 100
K = 3
MAX = 60
LAST_TURNS = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

update_last_turns = function(new_value)
	for i = 9, 1, -1 do
		LAST_TURNS[i + 1] = LAST_TURNS[i]
	end
	LAST_TURNS[1] = new_value
end

-- different strategies that can be adopted by the agents
function d_same_last_week(t)    return t[1]                            end
function d_same_plus_10(t)      return t[1] + 10                       end
function d_mirror_last_week(t)  return 100 - t[1]                      end
function d_67()                 return 67                              end
function d_same_2_weeks(t)      return t[2]                            end
function d_same_5_weeks(t)      return t[5]                            end
function d_average_4_weeks(t)   return (t[1] + t[2] + t[3] + t[4]) / 4 end
function d_average_2_weeks(t)   return (t[1] + t[2]) / 2               end
function d_max_2_weeks(t)       return math.max(t[1], t[2])            end
function d_min_2_weeks(t)       return math.min(t[1], t[2])            end

STRATEGIES = {d_same_last_week, d_same_plus_10, d_mirror_last_week, d_67, d_same_2_weeks,
              d_same_5_weeks, d_average_4_weeks, d_max_2_weeks, d_min_2_weeks}

NAMES_STRATEGIES = {
	[d_same_last_week]   = "d_same_last_week",
	[d_same_plus_10]     = "d_same_plus_10",
	[d_mirror_last_week] = "d_mirror_last_week",
	[d_67]               = "d_67",
	[d_same_2_weeks]     = "d_same_2_weeks",
	[d_same_5_weeks]     = "d_same_5_weeks",
	[d_average_4_weeks]  = "d_average_4_weeks",
	[d_max_2_weeks]      = "d_max_2_weeks",
	[d_min_2_weeks]      = "d_min_2_weeks"
}

c = Cell{agents_in_the_bar = 0}

list_attributes = {}

forEachElement(NAMES_STRATEGIES, function(_, name)
	c[name] = 0
	list_attributes[#list_attributes + 1] = name
end)

Chart{
	subject = c,
	select = {"agents_in_the_bar"},
	symbol = "hexagon",
	size = 7,
	yLabel = "percentage"
}

Chart{
	subject = c,
	select = list_attributes
}

function count_strategies(soc)
	tot = {}
	for i = 1, #STRATEGIES do
		tot[STRATEGIES[i]] = 0
	end

	forEachAgent(soc, function(agent)
		strat = agent.strategies[agent.last_strategy]
		tot[strat] = tot[strat] + 1
	end)

	for i = 1, #STRATEGIES do
		strat = STRATEGIES[i]
		c[NAMES_STRATEGIES[strat]] = tot[strat]
	end
end

beerAgent = Agent{
	init = function(ag)
		ag.strategies = {}
		ag.count_fails = {}

		-- choose K different strategies
		ag.chosen = {0, 0, 0, 0, 0, 0, 0, 0, 0}
		for i = 1, K do
			ag.count_fails[i] = 0
			p = 0
			repeat
				p = math.random(1, #STRATEGIES)
			until ag.chosen[p] == 0
			ag.strategies [i] = STRATEGIES[p]
			ag.chosen[p] = 1
		end

		ag.last_strategy = 1
	end,
	execute = function(ag)
		best = 1
		for i = 2, K do
			if ag.count_fails[best] > ag.count_fails[i] then
				best = i
			end
		end

		ag.last_strategy = best

		last = ag.strategies[best](LAST_TURNS)
		if last < 60 then
			ag.last_choose = 1
		else
			ag.last_choose = 0
		end
		return ag.last_choose
	end,
	update = function(ag, quantity)
		for i = 1, K do
			-- punishment is equal to the difference btw the predicted value
			-- and the number of attendances
			diff = ag.strategies[i](LAST_TURNS) - quantity
			ag.count_fails[i] = ag.count_fails[i] + math.abs(diff)
		end
	end
}

s = Society{
	instance = beerAgent, 
	quantity = N
}

t = Timer{
	Event{action = function(ev)
		quant = 0
		forEachAgent(s, function(ag)
			quant = quant + ag:execute()
		end)
		c.agents_in_the_bar = quant
		count_strategies(s)
		c:notify(ev:getTime())

		forEachAgent(s, function(ag)
			ag:update(quant)
		end)

		update_last_turns(quant)
	end}
}

t:execute(100)

