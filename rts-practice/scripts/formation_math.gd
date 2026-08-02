class_name FormationMath
extends RefCounted

static func hungarian_assign(cost: Array) -> Array:
	var n: int = cost.size()
	var INF: float = 1e18
	
	var u: Array = []
	var v: Array = []
	var p: Array = []
	var way: Array = []
	for i in n + 1:
		u.append(0.0)
		v.append(0.0)
		p.append(0)
		way.append(0)
	
	for i in range(1, n + 1):
		p[0] = i
		var j0: int = 0
		var j1: int = -1
		var minv: Array = []
		var used: Array = []
		for j in n + 1:
			minv.append(INF)
			used.append(false)
		
		while true:
			used[j0] = true
			var i0: int = p[j0]
			var delta: float = INF
			j1 = -1
			
			for j in range(1, n + 1):
				if not used[j]:
					var cur: float = cost[i0 - 1][j - 1] - u[i0] - v[j]
					if cur < minv[j]:
						minv[j] = cur
						way[j] = j0
					if minv[j] < delta:
						delta = minv[j]
						j1 = j
			
			for j in n + 1:
				if used[j]:
					u[p[j]] += delta
					v[j] -= delta
				else:
					minv[j] -= delta
			
			j0 = j1
			if p[j0] == 0:
				break
		
		while j0 != 0:
			j1 = way[j0]
			p[j0] = p[j1]
			j0 = j1
	
	var result: Array = []
	for i in n: result.append(0)
	for j in range(1, n + 1):
		if p[j] > 0:
			result[p[j] - 1] = j - 1
	return result
