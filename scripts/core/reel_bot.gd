class_name ReelBot
extends RefCounted
## Çekişme botu: bir oyuncu tarzını taklit eder (testler ve tools/reel_report.gd için).
## - PERFECT: patlama başlamadan hemen önce bırakır, biter bitmez yeniden basar.
## - REACT: uyarıdan (warn) reaction adım sonra bırakır, patlama bitişinden reaction adım sonra basar.
## - ALWAYS: hep basılı tutar. NEVER: hiç basmaz.

enum Style { PERFECT, REACT, ALWAYS, NEVER }

## Bir çekişme bu kadar adımda bitmezse "bitmedi" sayılır (2 dakika).
const LIMIT_STEPS := 120 * FishingRules.HZ

var style: Style = Style.PERFECT
var reaction: int = 24

var _release_at: int = -1
var _press_at: int = -1


static func make(bot_style: Style, reaction_seconds: float = 0.0) -> ReelBot:
	var bot := ReelBot.new()
	bot.style = bot_style
	bot.reaction = FishingRules.to_steps(reaction_seconds)
	return bot


## Bir sonraki adımda basılı tutulsun mu? events: modelin son adımda verdiği olaylar.
func decide(model: ReelModel, events: PackedStringArray) -> bool:
	match style:
		Style.ALWAYS:
			return true
		Style.NEVER:
			return false
		Style.PERFECT:
			return not (model.phase == ReelModel.Phase.BURST
					or (model.phase == ReelModel.Phase.WARN and model.phase_steps <= 1))
	for e in events:
		if e == "warn":
			_release_at = model.steps + reaction
		elif e == "burst_end":
			_press_at = model.steps + reaction
	var hold := model.holding
	if _release_at >= 0 and model.steps >= _release_at:
		hold = false
		_release_at = -1
	if _press_at >= 0 and model.steps >= _press_at:
		hold = true
		_press_at = -1
	return hold


## Bir çekişmeyi baştan sona oynar. Döner: { outcome (ReelModel.Outcome), seconds, red (kırmızıda
## geçen sn) }.
static func play(model: ReelModel, bot: ReelBot) -> Dictionary:
	model.holding = bot.style != Style.NEVER
	var events := PackedStringArray()
	var red_steps := 0
	while model.outcome == ReelModel.Outcome.NONE and model.steps < LIMIT_STEPS:
		model.holding = bot.decide(model, events)
		events = model.step()
		if model.in_red:
			red_steps += 1
	return { "outcome": model.outcome, "seconds": model.seconds(), "red": float(red_steps) / FishingRules.HZ }
