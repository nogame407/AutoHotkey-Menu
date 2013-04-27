class menu
{

	static _init_ := MENU_init()
	static destroy := Func("MENU_delete")

	class _properties_
	{

		__Call(target, name, params*) {
			if !(name ~= "i)^(base|__Class)$") {
				return ObjHasKey(this, name)
				       ? this[name].(target, params*)
				       : this.__.(target, name, params*)
			}
		}
	}
	
	__New(name) {
		ObjInsert(this, "_", []) ; proxy object
		try (this.name := name)
		catch e
			throw Exception(e.Message, -1)
		this[this.name] := true
	}

	__Delete() {
		try {
			if this.isMenu
				this.destroy()
		}	
		OutputDebug, Class: menu released.
	}

	class __Set__ extends menu._properties_
	{

		__(key, value) {
			if (key == this.name)
				return MENU_list([key, value ? this : false]*)
			
			return this._[key] := value
		}

		name(value) {
			if this._.HasKey("name")
				throw Exception("The 'name' property is read-only.", -1)
			if this.handle[value]
				throw Exception("Menu name already exists.", -1)
			for i, j in ["Standard", "NoStandard"]
				Menu, % value, % j
			
			return this._["name"] := value
		}

		default(value) {
			Menu, % this.name, Default
			    , % value ? (IsObject(value) ? value.name : value) : ""
		    
		    return this._["default"] := value
		}

		standard(value) {
			std := this.standard ? 1 : 0
			cmd := {0: "NoStandard"
			    ,   1: "Standard"
			    ,   2: ({0: "Standard", 1: "NoStandard"}[std])}[value]

		    value := {"$": (value ? {0: true, 1: false}[std] : false)
		          ,   "@": (value ? this.count+1 : 0)}
		    
		    p := (s := value["$"]) ? this.count : this.standard
		    Menu, % this.name, % cmd    
		    Loop, 10
		    	(this.item)[s ? p+A_Index : p] := s
		    	                               ? new menu._item_(this, {name: []})
		    	                               : ""
		    
		    return this._["standard"] := value
		}

		color(value) {
			static sg := {1: 1, 0: 0, "true": 1, "false": 0, single: 1, "": 0}
			
			if IsObject(value) {
				mi := value.MinIndex() ? true : false
				Menu, % this.name, Color
				    , % (v := mi ? value.1 : value.value)
				    , % (s := sg[mi ? value.2 : value.single]) ? "Single" : ""
			
			} else {
				RegExMatch(value, "iO)^(.*)[,\|\s](1|0|true|false|single)$", cv)
				Menu, % this.name, Color
				    , % (v := cv ? cv.1 : value)
				    , % (s := sg[cv ? cv.2 : 0]) ? "Single" : ""
			}
			return this._["color"] := {value: v, single: s}
		}
	
	}

	__Set(key, value) {
		if (key = "name") {
			if this._.HasKey(key)
				throw Exception("The 'name' property is read-only.", -1)
			if this.handle[value]
				throw Exception("Menu name already exists.", -1)
			for i, j in ["Standard", "NoStandard"] ; create empty Menu
				Menu, % value, % j
		}
		
		if (key == this.name)
			return MENU_list([key, value ? this : false]*)

		if (key = "default") {
			Menu, % this.name, Default
			    , % value ? (IsObject(value) ? value.name : value) : ""
		}

		if (key = "standard") {
			std := this.standard ? 1 : 0
			cmd := {0: "NoStandard"
			    ,   1: "Standard"
			    ,   2: ({0: "Standard", 1: "NoStandard"}[std])}[value]

		    value := {"$": (value ? {0: true, 1: false}[std] : false)
		          ,   "@": (value ? this.count+1 : 0)}
		    
		    p := (s := value["$"]) ? this.count : this.standard ; this.standard["@"]
		    Menu, % this.name, % cmd    
		    Loop, 10
		    	(this.item)[s ? p+A_Index : p] := s
		    	                               ? new menu._item_(this, {name: []})
		    	                               : ""    	
		}

		if (key = "color") {
			sg := {1: 1, 0: 0, "true": 1, "false": 0, single: 1, "": 0}
			if IsObject(value) {
				mi := value.MinIndex() ? true : false
				Menu, % this.name, Color
				    , % (v := mi ? value.1 : value.value)
				    , % (s := sg[mi ? value.2 : value.single]) ? "Single" : ""
			
			} else {
				RegExMatch(value, "iO)^(.*)[,\|\s](1|0|true|false|single)$", cv)
				Menu, % this.name, Color
				    , % (v := cv ? cv.1 : value)
				    , % (s := sg[cv ? cv.2 : 0]) ? "Single" : ""
			}
			value := {value: v, single: s}
		}
		
		return this._[key] := value
	}

	class __Get extends menu._properties_
	{

		__(key, params*) {			
			if ObjHasKey(this._, key)
				return this._[key, params*]

			if (key ~= "i)^(hMenu|hwnd)$")
				return this.handle[params*]

			return false
		}

		isMenu(p*) {
			return DllCall("IsMenu", "Ptr", this.hwnd)
		}

		handle(p*) {
			static hDummy

			if !hDummy {
				Menu, mDummy, Add
				Menu, mDummy, DeleteAll
				Gui, New, +LastFound
				Gui, Menu, mDummy
				hDummy := DllCall("GetMenu", "Ptr", WinExist())
				Gui, Menu
				Gui, Destroy
				if !hDummy
					return false
			}
			try Menu, mDummy, Add, % ":" (mn := p.1 ? p.1 : this.name)
			catch
				return false
			hMenu := DllCall("GetSubMenu", "Ptr", hDummy, "Int", 0)
			DllCall("RemoveMenu", "Ptr", hDummy, "UInt", 0, "UInt", 0x400)
			Menu, mDummy, Delete, % ":" mn
			return hMenu
		}

		count(p*) {	
			return (c := DllCall("GetMenuItemCount", "Ptr", this.hwnd)) < 0 ? 0 : c
		}
		
		standard(p*) {
			if !this._.HasKey("standard")
				return false
			for x, y in this.item.()
				pos := x
			until (std := (y.type = "Standard"))
			return std ? (p.1 ? this._.standard[p.1] : pos) : false
		}

		default(p*) {
			idx := DllCall("GetMenuDefaultItem"
				         , "Ptr", this.hwnd
				         , "UInt", true
				         , "UInt", 0x0001L) ; GMDI_USEDISABLED
			
			return (idx >= 0) ? (this.item)[idx+1] : false
		}
	
	}

	add(item:="") {
		if !IsObject(this.item)
			this.item := new menu._menuitems_(this)
		mi := new menu._item_(this, item)
		(this.item)[this.count] := mi
	}

	insert(p1:=0, p2:=0) {
		this.add((mi := IsObject(p1)) ? p1 : "")
		(this.item)[this.count].pos := mi ? p2 : p1
	}

	delete(item:="") {
		if item
			(this.item)[item] := ""
		else (this.item := "")
	}

	show(x:="", y:="", coordmode:="") {
		if (coordmode && (x <> "" || y <> "")) {
			if (coordmode ~= "i)^(Screen|Relative|Window|Client)$")
				CoordMode, Menu, % coordmode
		}	
		Menu, % this.name, Show, % x, % y
	}

	class _menuitems_
	{
		
		static _keys_ := menu._menuitems_.__([[], [], []])

		__New(self) {		
			for a, b in this.base._keys_
				this.Insert(b, (a <= 2 ? [] : self.name))
		}

		__Set(key, value) {
			if (key ~= "^\d+$") {			
				if (IsObject(value) && value.__Class = "menu._item_") {
					if (value.type ~= "i)^(Normal|Submenu)$")
						this.ins([value.name, true], 2)
				
				} else {
					if (this[key].type ~= "i)^(Normal|Submenu)$")
						this.del(this[key].name, 2)
					this.set([key, ""]) , this.del(key)
					return true
				}
			
			} else if this.has(key, 2)
				return this[this[key].pos] := value

			return this.ins([key, value])
		}

		class __Get extends menu._properties_
		{

			__(key, params*) {
				if this.has(key)
					return this.get([key, params*])
				else if this.has(key, 2) {
					for a, b in this.()
						idx := a
					until (n := (b.name = key))
					return n ? this[idx] : false
				}
			}
		}

		__Call(method, params*) {
			
			if (method ~= "i)^(get|set|ins|has|del)$") {
				m := {ins: "Insert", del: "Remove", has: "HasKey", get: 1, set: 0}[method]
				k := this.__(params.2 ? params.2 : 1)
				p := IsObject(params.1) ? params.1 : [params.1]

				return (m ~= "i)[A-Z]+")
				       ? (this[k])[m](p*)
				       : (m ? this[k][p*] : ((this[k])[p.1] := p.2))
			}

			if (method = "menu")
				return MENU_obj(this[this.__(3)])

			if (method ~= "i)^(delete|move)$")
				return this["$"](params*)

			if !method
				return this[this.__(params.1 ? params.1 : 1)]
		}

		; PRIVATE
		__(k) {
			static keys

			return keys ? ((k == keys) ? 0 : (keys.HasKey(k) ? keys[k] : 0)) : (keys := k)
		}

		$(item, pos:=false) {
			self := this.menu()

			if pos
				this.ins([pos, this.del(item.pos)])
			
			Menu, % self.name, DeleteAll
			Menu, % self.name, NoStandard

			for k, v in this.() {
				if (!pos && v == item)
					continue
				if (v.type = "Standard") {
					if (k = self.standard)
						Menu, % self.name, Standard
					continue
				}
				Menu, % self.name, Add
				    , % (z := v._.HasKey("name")) ? v._.name : ""
				    , % z ? "MenuItemEventHandlerLabel" : ""
			    for x, y in v._ {
			    	if (x ~= "i)^(name|menu)$")
			    		continue
			    	this[k][x] := y
			    }
			}
		}
	
	}

	class _item_
	{

		__New(self, item) {
			this.Insert("_", {menu: self.name})
			;ObjInsert(this, "_", {menu: self.name})
			
			if IsObject(item) {
				this.name := item.name
				if (!item.Haskey("target") && !IsObject(item.name))
					item.target := ""
				
				for a, b in item
					this[a] := b
				
			} else Menu, % self.name, Add
		}

		__Delete() {

			if this.menu.isMenu {
				self := this.menu
				if (this.type <> "Standard")
					self.item.delete(this)
			}
			;OutputDebug, % "Class: " this.__Class " released"
		}

		__Set(key, value) {
			self := this.menu

			if (key = "name") {
				if this._.HasKey(key) {
					if (this.type = "Standard") ; <stditem>
						return false
					if (this.name = value)
						return false
					self.item.del(this.name, 2)
					Menu, % self.name, Rename, % this.name, % value
					self.item.ins([this.name, true], 2)
				} else {
					if !IsObject(value)
						Menu, % self.name, Add
						    , % value
						    , MenuItemEventHandlerLabel
				}
			}

			if (key = "target") {
				sm := ((sm1 := SubStr(value, 1, 1) = ":") || (IsObject(value) && (value.__Class = "menu")))
				   ?  (sm1 ? value : ":" value.name)
				   :  false
					
				if sm
					Menu, % self.name, Add, % this.name, % sm

	    		value := (value == "" ? this.name : value)
			}
			
			if (key = "icon") {
				if RegExMatch(value, "O)^(.*),(\d+)$", icon)
					Menu, % self.name, Icon, % this.name, % icon.1, % icon.2
				else
					Menu, % self.name, Icon, % this.name, % value
			}

			if (key ~= "i)^(check|enable)$") {
				cmd := {check: {1: "Check", 0: "Uncheck", 2: "ToggleCheck"}
			        ,   enable: {1: "Enable", 0: "Disable", 2: "ToggleEnable"}}[key, value]
		        
		        Menu, % self.name, % cmd, % this.name
			}

			if (key = "default")
				self.default := value ? this.name : false

			if (key = "pos") {
				if !(value >= 1 && value <= self.count && value <> this.pos)
					return false
				if (pos := self.standard) {
					if (value > this.pos && value >= pos && value < (pos+9))
						return false
					if (value < this.pos && value > pos && value <= (pos+9))
						return false
				}
				self.item.move(this, value)
				return true
			}

			return this._[key] := value
		}

		class __Get extends menu._properties_
		{

			__(key, params*) {
				if ObjHasKey(this._, key)
					return this._[key, params*]			
			}

			name(p*) {
				static NULL := ""
				
				if (this.type = "Separator")
					return
				len := DllCall("GetMenuString"
				             , "Ptr", this.menu.handle
				             , "UInt", this.pos-1
				             , "Str", NULL
				             , "Int", 0
				             , "UInt", 0x400)
				VarSetCapacity(name, (len+1)*(A_IsUnicode ? 2 : 1))
				len := DllCall("GetMenuString"
				             , "Ptr", this.menu.handle
				             , "UInt", this.pos-1
				             , "Str", name
				             , "Int", len+1
				             , "UInt", 0x400)
				return (len ? name : "")
			}

			menu(p*) {
				return MENU_obj(this._.menu)
			}

			pos(p*) {
				self := this.menu
				Loop, % self.count
					pos := A_Index
				until ((self.item)[pos] == this)
				return pos
			}

			type(p*) {
				id := this.id , std := IsObject(this._.name)
				return {1: std ? "Standard" : "Normal"
				     ,  0: std ? "Standard" : "Separator"
				     , -1: "Submenu"}[id <= 0 ? id : 1]
			}

			id(p*) {
				return DllCall("GetMenuItemID", "Ptr", this.menu.hwnd, "UInt", this.pos-1)
			}

			check(p*) {
				return (this.fState & 0x8) ? true : false
			}

			enable(p*) {
				return (this.fState & 0x3) ? false : true
			}
			; PRIVATE
			fState(p*) {	
				VarSetCapacity(MII, 48, 0) ; sizeof(MENUITEMINFO)
				Numput(48, MII, 0) ; set cbSize field to sizeof(MENUITEMINFO)
				NumPut(1, MII, 4) ; set fMask to MIIM_STATE=1
				DllCall("GetMenuItemInfo"
				      , "Ptr", this.menu.handle
				      , "UInt", this.pos-1
				      , "UInt", 1
				      , "UInt", &MII)
				
				return NumGet(MII, 12) ; get fState field out of struct
			}
		
		}

		onEvent() {
			t := this.target
			lbl := IsLabel(t) , fn := IsFunc(t) , obj := IsObject(t)
			if ((lbl && !fn) || (lbl && fn))
				SetTimer, % this.target, -1
			else if ((fn && !lbl) || (obj && IsFunc(t.Name)))
				return (this.target).()
			return
			MenuItemEventHandlerLabel:
			MenuItemEventHandlerTimerLabel:
			if InStr(A_ThisLabel, "Timer")
				menu.thisItem.onEvent()
			else SetTimer, MenuItemEventHandlerTimerLabel, -1		
			return
		}
	
	}

	class _BASE_
	{

		class __Get extends menu._properties_
		{

			__(key, p*) {
				if RegExMatch(key, "Oi)^(this(Menu|Item))$", m)
					return MENU_obj({menu: [A_ThisMenu]
					               , item: [A_ThisMenu, A_ThisMenuItem]}[m.2]*)
				
				return MENU_obj(key, p*)
			}
		
		}
	
	}

}
; PUBLIC FUNCTIONS
MENU_delete(ByRef this) {
	if (!IsObject(this) || (this.base <> menu))
		throw Exception("[Invalid Parameter] Not a menu object.", -1)

	this[this.name] := false
	this.item := ""
	Menu, % this.name, Delete
	return IsByRef(this) ? (true, this := "") : false
}

MENU_obj(name, p*) {
	if MENU_list(name, 2) {
		m := MENU_list(name)
		return p.1 ? (IsObject(mi:=m.item[p.1]) ? mi : false) : m
	
	} else if DllCall("IsMenu", "Ptr", name) {
		for k, v in MENU_list()
			mn := v
		until (found := (mn.hwnd == name))
		return found ? mn : false
	
	} else return false
}

MENU_from(src) {
	static MSXML := "MSXML2.DOMDocument" (A_OSVersion ~= "(7|8)" ? ".6.0" : "")
	, xpr := ["*[translate(name(), 'MENU', 'menu')='menu']"
	      ,   "*[translate(name(), 'ITEM', 'item')='item']"
	      ,   "@*[translate(name(), 'NAME', 'name')='name']"
	      ,   "i)^(name|target|icon|check|enable|default)$"]
	
	if !IsObject(menu)
		throw Exception("Cannot create menu(s) from XML source. "
		      . "Super-global variable 'menu' is not an object.", -1)
	
	x := ComObjCreate(MSXML)
	x.async := false

	; Load XML source
	if (src ~= "s)^<.*>$")
		x.loadXML(src)
	else if ((f:=FileExist(src)) && !(f ~= "D"))
		x.load(src)
	else throw Exception("Invalid XML source.", -1)

	m := [] , mn := []
	root := x.documentElement
	_m_ := root.selectNodes(xpr.1)

	if !(len := _m_.length) {
		n := root.selectSingleNode(xpr.3)
		mn[n.value] := root
		m[n.value] := new menu(n.value)
	} else Loop, % len {
		node := _m_.item(A_Index-1)
		n := node.selectSingleNode(xpr.3)
		mn[n.value] := node
		m[n.value] := new menu(n.value)
	}
	
	; Add item(s)
	for k, v in m {
		_mi_ := mn[k].selectNodes(xpr.2)
		
		; Set item(s) properties
		Loop, % _mi_.length {
			_p_ := _mi_.item(A_Index-1).attributes
			
			item := _p_.length ? [] : ""
			Loop, % _p_.length {	
				p := _p_.item(A_Index-1)
				if (p.name ~= xpr.4)
					item[p.name] := p.value	
			}		
			v.add(item)
		}
	}	
	return len ? m : m[n.value]
}

MENU_to(p*) {
	static MSXML := "MSXML2.DOMDocument" (A_OSVersion ~= "(7|8)" ? ".6.0" : "")

	x := ComObjCreate(MSXML)
	mn := {base: {max: Func("ObjMaxIndex"), del: Func("ObjRemove")}} , mi := []
	for k, v in p {
		mn[k] := x.createElement("Menu")
		mn[k].setAttribute("name", v.name)

		for a, b in v.item.() {
			mi[a] := x.createElement("Item")

			for i, j in b._ {
				if (i = "menu")
					continue
				mi[a].setAttribute(i, IsObject(j) ? (j.__Class = "menu" ? ":" j.name : j.name) : j)
			}
			mn[k].appendChild(mi[a])
		}
	}

	x.documentElement := (mn.max() > 1) ? x.createElement("MENU") : mn.del()
	for y, z in mn
		x.documentElement.appendChild(z)

	return x
}

; PRIVATE FUNCTIONS
MENU_init() {
	static init
	static $ := menu.Remove("_init_")

	if init ; call once
		return
	menu.base := menu._BASE_
	init := true
}

MENU_list(k:="", v:=1) {
	static list := []

	if (k == "")
		return list
	if IsObject(v)
		list[k] := v
	else {
		if v
			return {1: list[k], 2: list.HasKey(k)}[v]
		else list.Remove(k)
	}
	return true
}