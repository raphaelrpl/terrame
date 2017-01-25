-- @example Implementation of beer economic chain model.
-- This model represents an economic chain with a manufacturer, some intermediate nodes (such as
-- a distributor and a supplier), and a retailer. The agents in the economic chain need to fill
-- their demand by requesting beer to the previous agent of the chain.
-- The retailer has a random demand, while the others have a demand requested by the next
-- agent of the chain. Each requested beer takes three time steps to be delivered from one agent
-- to the next one (as long as there is some stock to fulfil the demand).
-- The objective of the game is to minimize expenditure from back orders and inventory. \
-- For more information, see https://en.wikipedia.org/wiki/Beer_distribution_game.
-- @arg NUMBER_OF_AGENTS Number of agents in the chain, excluding the manufacturer and the retailer.
-- The default value is three.
-- @image beer.bmp

math.randomseed(os.time())

NUMBER_OF_AGENTS = 3

RequestBeer = function(agent, quantity)
	agent:message{receiver = agent.from, delay = 1, content = "request", value = quantity}
	agent.requested = quantity
end

SendBeer = function(agent, quantity)
	agent:message{receiver = agent.to, content = "deliver", delay = 3,  value = quantity}
	agent.sended = quantity
end

COUNTER = 1
chainAgent = Agent{
	init = function(agent)
		agent.stock     = 20
		agent.ordered   = 0
		agent.costs     = 0
		agent.received  = 0
		agent.priority  = COUNTER
		COUNTER = COUNTER + 1
	end,
	update_costs = function(agent)
		agent.costs = agent.costs + math.floor(agent.stock / 2) + agent.ordered
	end,
	execute = function(agent)
		if agent.ordered <= agent.stock then
			SendBeer(agent, agent.ordered)
			agent.stock = agent.stock - agent.ordered
			agent.ordered = 0
		else
			SendBeer(agent, agent.stock)
			agent.ordered = agent.ordered - agent.stock
			agent.stock = 0
		end

		-- the overall decision
		-- how many beers will I request according to my [stock] and the [ordered] amount of beer that I could not deliver?
		local requested = 0
		if agent.stock <= 20 then
			requested = 6 + agent.ordered * 0.05
		end

		RequestBeer(agent, requested)
		-- end of the overall decision

		agent:update_costs()
	end,
	on_message = function(agent, message)
		if message.content == "request" then
			agent.ordered = agent.ordered + message.value
		elseif message.content == "deliver" then
			agent.stock = agent.stock + message.value
			agent.received = message.value
		end
	end
}

c = Cell{
	beer_requested = 0,
	beer_delivered = 0,
	total_cost = 0
}

chartDeliv = Chart{
	target = c,
	select = {"beer_requested", "beer_delivered"},
	color = {"red", "blue"}
}

chartCost = Chart{
	target = c,
	select = "total_cost",
	color = "black",
	style = "sticks"
}

retailer = Agent{
	priority  = 0,
	received  = 0,
	ordered   = 0,
	costs     = 0,
	execute = function(agent)
		local requested = math.random(30)
		c.beer_requested = requested
		RequestBeer(agent, requested)
	end,
	on_message = function(agent, message)
		if message.content == "deliver" then
			agent.received = message.value
			c.beer_delivered = message.value
		end
	end
}

manufacturer = Agent{
	priority = NUMBER_OF_AGENTS + 1,
	received  = 0,
	ordered   = 0,
	costs     = 0,
	execute = function(agent)
		SendBeer(agent, agent.ordered)
		agent.ordered = 0
	end,
	on_message = function(agent, message)
		if message.content == "request" then
			agent.ordered = message.value
		end
	end
}

s = Society{
	instance = chainAgent,
	quantity = NUMBER_OF_AGENTS
}

s:add(retailer)
s:add(manufacturer)

-- defines the order to execute the agents
g = Group{
	target = s,
    greater = function(a, b) return a.priority < b.priority end
}

-- connects the i'th agent to the i+1'th
last = {}
forEachAgent(g, function(ag)
	ag.to     = last
	last.from = ag
	last      = ag
end)

t = Timer{
	Event{action = function()
		s:execute()
		s:synchronize()
		c.total_cost = 0

		forEachAgent(s, function(agent)
			c.total_cost = c.total_cost + agent.costs
		end)
	end},
	Event{action = chartDeliv},
	Event{action = chartCost}
}

t:run(500)

