GRAPH_RENDERER = graph-easy
MODE = ascii
VIEWER = type
PREPROCESSOR = m4
flow.txt : flow.dot
	$(GRAPH_RENDERER) -as=$(MODE) --output=$@ $<
	$(VIEWER) $@
