tool
extends Spatial
onready var env:Environment = $Environment.environment
onready var sun:DirectionalLight = $SunMoon
onready var sky_view:Viewport = $SkyViewport
onready var clouds_view:Viewport = $CloudsViewport
onready var sky_tex:Sprite = $SkyViewport/SkyTexture
onready var clouds_tex:Sprite = $CloudsViewport/CloudsTexture

export (int) var clouds_resolution = 1024 setget set_clouds_resolution
export (int) var sky_resolution = 1024 setget set_sky_resolution

export (GradientTexture) var sky_gradient_texture:GradientTexture setget set_sky_gradient
export (bool) var SCATERRING = true setget set_SCATERRING
export (Color, RGBA) var color_sky = Color(0.156863, 0.392157, 1, 1) setget set_color_sky
export (float, 0.0, 10.0, 0.0001) var sky_tone = 3.5 setget set_sky_tone
export (float, 0.0, 2.0, 0.0001) var sky_density = 0.5 setget set_sky_density
export (float, 0.0, 10.0, 0.0001) var sky_rayleig_coeff = 1 setget set_sky_rayleig_coeff
export (float, 0.0, 10.0, 0.0001) var sky_mie_coeff = 0.5 setget set_sky_mie_coeff
export (float, 0.0, 2.0, 0.0001) var multiScatterPhase = 0.0 setget set_multiScatterPhase
export (float, -2.0, 2.0, 0.0001) var anisotropicIntensity = 1.5 setget set_anisotropicIntensity

export (float, 0.0, 23.99, 0.01) var time_of_day = 14.0 setget set_time_of_day

export (float, 0.0, 1.0, 0.0001) var clouds_coverage = 0.5 setget set_clouds_coverage
export (float, 0.0, 10.0,0.0001) var clouds_size = 2.0 setget set_clouds_size
export (float, 0.0, 10.0, 0.0001) var clouds_softness = 1.0 setget set_clouds_softness
export (float, 0.0, 1.0, 0.0001) var clouds_dens = 0.1215 setget set_clouds_dens
export (float, 0.0, 1.0, 0.0001) var clouds_height = 0.35 setget set_clouds_height
export (int, 5, 100) var clouds_quality = 100 setget set_clouds_quality
var sun_pos:Vector3
var moon_pos:Vector3
var iTime = 0.0

export (Color, RGBA) var moon_light = Color(0.6, 0.6, 0.8, 1.0)
export (Color, RGBA) var sunset_light = Color(1.0, 0.7, 0.55, 1.0)
export (float, -0.3, 0.3, 0.000001) var sunset_offset = -0.1
export (float, 0.0, 0.3, 0.000001) var sunset_range = 0.2
export (Color, RGBA) var day_light = Color(1.0, 1.0, 1.0, 1.0)
export (Color, RGBA) var moon_tint = Color(1.0, 0.7, 0.35, 1.0) setget set_moon_tint
export (Color, RGBA) var clouds_tint = Color(1.0, 1.0, 1.0, 1.0) setget set_clouds_tint
export (float, 0.0, 1.0, 0.0001) var sun_radius = 0.04 setget set_sun_radius 
export (float, 0.0, 0.5, 0.0001) var moon_radius = 0.05 setget set_moon_radius
export (float, -1.0, 1.0, 0.0001) var moon_phase = -1.0 setget set_moon_phase
export var night_level_light = 0.1 setget set_night_level_light
export (int, 0, 359) var wind_dir = 130 setget set_wind_dir
export (float, 0.0, 10.0, 0.1) var wind_strength = 7.0 setget set_wind_strength
export var lightning_pos: Vector3=Vector3(2.0, 2.0, 2.0) setget set_lightning_pos

func set_call_deff_shader_params(node: Material, params:String, value):
	node.set(params,value)

func set_clouds_resolution(value:int):
	clouds_resolution = value
	if is_inside_tree():
		clouds_view.size = Vector2(clouds_resolution, clouds_resolution)
		clouds_tex.texture.set_size_override(Vector2(clouds_resolution, clouds_resolution))

func set_sky_resolution(value:int):
	sky_resolution = value
	if is_inside_tree():
		sky_view.size = Vector2(sky_resolution, sky_resolution)
		sky_tex.texture.set_size_override(Vector2(sky_resolution, sky_resolution))

func _ready():
	set_lightning_strike(false)
	call_deferred("_set_attenuation", 3.0)
	call_deferred("_set_exposure", 1.0)
	call_deferred("_set_light_size", 0.2)
	call_deferred("set_color_sky", color_sky)
	call_deferred("set_moon_tint", moon_tint)
	call_deferred("set_clouds_tint", clouds_tint)
	call_deferred("set_moon_phase", moon_phase)
	call_deferred("set_moon_radius", moon_radius)
	call_deferred("set_wind_strength", wind_strength)
	call_deferred("set_clouds_quality", clouds_quality)
	call_deferred("set_clouds_height", clouds_height)
	call_deferred("set_clouds_coverage", clouds_coverage)
	call_deferred("set_time")
	call_deferred("reflections_update")

func reflections_update():
	env.background_sky.set_panorama(sky_view.get_texture())

func set_SCATERRING(value:bool):
	SCATERRING = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/SCATERRING", SCATERRING)

func set_sky_gradient(value:GradientTexture):
	sky_gradient_texture = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sky_gradient_texture", sky_gradient_texture)

func set_night_level_light(value:float):
	night_level_light = clamp(value, 0.0, 1.0)
	set_time()

func set_time_of_day(value:float):
	time_of_day = value
	set_time()

func set_time():
	if !is_inside_tree():
		return
	var light_color = Color(1.0, 1.0, 1.0, 1.0)
	var phi = time_of_day * 2.0 * PI / 24
	# here you can change the start position of the sun and axis of rotation
	sun_pos = Vector3(0.0,-1.0,0.0).normalized().rotated(Vector3(1.0,0.0,0.0).normalized(), phi)
	# same for the moon
	moon_pos = Vector3(0.0,1.0,0.0).normalized().rotated(Vector3(1.0,0.0,0.0).normalized(), phi)
	# this magical formula is for the shader
	var moon_tex_pos = Vector3(0.0,1.0,0.0).normalized().rotated(Vector3(1.0,0.0,0.0).normalized(),
				(phi + PI) * 0.5)
	call_deferred("set_call_deff_shader_params", sky_tex.material,
				"shader_param/MOON_TEX_POS", moon_tex_pos)
	# light intensity depending on the height of the sun
	var light_energy = smoothstep(sunset_offset, 0.4, sun_pos.y)
	call_deferred("set_call_deff_shader_params", sky_tex.material,
				"shader_param/SUN_POS", sun_pos)
	call_deferred("set_call_deff_shader_params", sky_tex.material,
				"shader_param/MOON_POS", moon_pos)
	call_deferred("set_call_deff_shader_params", clouds_tex.material,
				"shader_param/SUN_POS",-sun_pos)
	# clouds too bright with night_level_light
	call_deferred("set_call_deff_shader_params", sky_tex.material,
			"shader_param/attenuation", clamp(light_energy,night_level_light * 0.25, 1.00))
	light_energy = clamp(light_energy, night_level_light, 1.00);
	var sun_height: float = sun_pos.y - sunset_offset
	if sun_height < sunset_range:
		light_color=lerp(moon_light, sunset_light,
					clamp(sun_height / sunset_range, 0.0, 1.0))
	else:
		light_color=lerp(sunset_light, day_light,
					clamp((sun_height-sunset_range) / sunset_range, 0.0, 1.0))
	if sun_pos.y < 0.0:
		if moon_pos.normalized() != Vector3.UP:
			# move moon to position and look at center scene from position
			sun.look_at_from_position(moon_pos,Vector3.ZERO,Vector3.UP)
	else:
		if sun_pos.normalized() != Vector3.UP:
			# move sun to position and look at center scene from position
			sun.look_at_from_position(sun_pos, Vector3.ZERO, Vector3.UP)
	set_clouds_tint(light_color) # comment this, if you need custom clouds tint
	light_energy = light_energy * (1 - clouds_coverage * 0.5)
	sun.light_energy = light_energy
	sun.light_color = light_color
	env.ambient_light_energy = light_energy
	env.ambient_light_color = light_color
	env.adjustment_saturation = 1 - clouds_coverage * 0.5
	env.set_fog_color(light_color)

func set_clouds_height(value:float):
	clouds_height = clamp(value, 0.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/HEIGHT", clouds_height)

func set_clouds_coverage(value:float):
	clouds_coverage = clamp(value, 0.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/ABSORPTION", clouds_coverage + 0.75)
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/COVERAGE", 1.0 - (clouds_coverage * 0.7 + 0.1))
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/THICKNESS", clouds_coverage * 10.0 + 10.0)
		call_deferred("set_time")

func set_clouds_size(value:float):
	clouds_size = clamp(value, 0.0, 10.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/SIZE", clouds_size)

func set_clouds_softness(value:float):
	clouds_softness = clamp(value, 0.0, 10.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/SOFTNESS", clouds_softness)
		
func set_clouds_dens(value:float):
	clouds_dens = clamp(value, 0.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/DENS", clouds_dens)

func set_clouds_quality(value:int):
	clouds_quality = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
					"shader_param/STEPS", clamp(clouds_quality, 5, 100))

func set_wind_dir(value:int):
	wind_dir = value
	set_wind_strength(wind_strength)

func set_wind_strength(value:float):
	wind_strength = value
	if is_inside_tree():
		# calculate game coordinates from real world compass degrees
		var x_dir = cos(wind_dir * 2.0 * PI / 360.0)
		var z_dir = -sin(wind_dir * 2.0 * PI / 360.0)
		call_deferred("set_call_deff_shader_params", clouds_tex.material,
			"shader_param/WIND", Vector3(x_dir, 0.0, z_dir) * wind_strength / 100)
	
func set_sun_radius(value:float):
	sun_radius = clamp(value, 0.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sun_radius", value)

func set_moon_radius(value:float):
	moon_radius = clamp(value, 0.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/moon_radius", value)
	
func set_moon_phase(value:float):
	moon_phase = clamp(value, -1.0, 1.0)
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/MOON_PHASE", moon_phase)

func set_sky_tone(value:float):
	sky_tone = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sky_tone", sky_tone)

func set_sky_density(value:float):
	sky_density = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sky_density", sky_density)

func set_sky_rayleig_coeff(value:float):
	sky_rayleig_coeff = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sky_rayleig_coeff", sky_rayleig_coeff)
		
func set_sky_mie_coeff(value:float):
	sky_mie_coeff = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/sky_mie_coeff", sky_mie_coeff)

func set_multiScatterPhase(value:float):
	multiScatterPhase = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/multiScatterPhase", multiScatterPhase)

func set_anisotropicIntensity(value:float):
	anisotropicIntensity = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/anisotropicIntensity", anisotropicIntensity)

func set_color_sky(value:Color):
	color_sky = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/color_sky", color_sky)

func set_moon_tint(value:Color):
	moon_tint = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/moon_tint", moon_tint)

func set_clouds_tint(value:Color):
	clouds_tint = value
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/clouds_tint", clouds_tint)

func _process(delta:float):
	iTime += delta
	var lightning_strength = clamp(sin(iTime * 20.0), 0.0, 1.0)
	lightning_pos = lightning_pos.normalized()
	sun.light_color = day_light
	sun.light_energy = lightning_strength * 2
	call_deferred("set_call_deff_shader_params", sky_tex.material,
				"shader_param/LIGHTNING_POS", lightning_pos)
	call_deferred("set_call_deff_shader_params", sky_tex.material,
				"shader_param/LIGHTNING_STRENGTH",Vector3(lightning_strength,
				lightning_strength, lightning_strength))
	sun.look_at_from_position(lightning_pos, Vector3.ZERO, Vector3.UP)

func set_lightning_strike(on:bool):
	if on:
		set_process(true)
	else:
		set_process(false)
		iTime = 0.0
		if sky_tex:
			call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/LIGHTNING_STRENGTH", Vector3(0.0, 0.0, 0.0))
		set_time()

func set_lightning_pos(value):
	lightning_pos = value;
	if is_inside_tree():
		call_deferred("set_call_deff_shader_params", sky_tex.material,
					"shader_param/LIGHTNING_POS", lightning_pos.normalized())

func thunder():
	var thunder_sound:AudioStreamPlayer = $Thunder
	if thunder_sound.is_playing():
		return
	thunder_sound.play()
	yield(get_tree().create_timer(0.3), "timeout")
	set_lightning_strike(true)
	yield(get_tree().create_timer(0.8), "timeout")
	set_lightning_strike(false)
