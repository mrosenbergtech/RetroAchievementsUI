//
//  Console.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct Console: Codable, Identifiable {
    let id: Int
    let name: String
    let iconURL: String
    let active: Bool
    let isGameSystem: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case iconURL = "IconURL"
        case active = "Active"
        case isGameSystem = "IsGameSystem"
    }
}

struct ConsoleGameInfo: Codable, Identifiable {
    let title: String
    let id: Int
    let consoleID: Int
    let consoleName: String
    let imageIcon: String
    let numAchievements: Int
    let numLeaderboards: Int
    let points: Int
    let dateModified: String
    let forumTopicID: Int
    let hashes: [String]?

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case id = "ID"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case imageIcon = "ImageIcon"
        case numAchievements = "NumAchievements"
        case numLeaderboards = "NumLeaderboards"
        case points = "Points"
        case dateModified = "DateModified"
        case forumTopicID = "ForumTopicID"
        case hashes = "Hashes"
    }
}


class Consoles {
    var consoles: [Console] = []
    let consolesJSONString: String =
"""
[{"ID":1,"Name":"Genesis/Mega Drive","IconURL":"https://static.retroachievements.org/assets/images/system/md.png","Active":true,"IsGameSystem":true},{"ID":2,"Name":"Nintendo 64","IconURL":"https://static.retroachievements.org/assets/images/system/n64.png","Active":true,"IsGameSystem":true},{"ID":3,"Name":"SNES/Super Famicom","IconURL":"https://static.retroachievements.org/assets/images/system/snes.png","Active":true,"IsGameSystem":true},{"ID":4,"Name":"Game Boy","IconURL":"https://static.retroachievements.org/assets/images/system/gb.png","Active":true,"IsGameSystem":true},{"ID":5,"Name":"Game Boy Advance","IconURL":"https://static.retroachievements.org/assets/images/system/gba.png","Active":true,"IsGameSystem":true},{"ID":6,"Name":"Game Boy Color","IconURL":"https://static.retroachievements.org/assets/images/system/gbc.png","Active":true,"IsGameSystem":true},{"ID":7,"Name":"NES/Famicom","IconURL":"https://static.retroachievements.org/assets/images/system/nes.png","Active":true,"IsGameSystem":true},{"ID":8,"Name":"PC Engine/TurboGrafx-16","IconURL":"https://static.retroachievements.org/assets/images/system/pce.png","Active":true,"IsGameSystem":true},{"ID":9,"Name":"Sega CD","IconURL":"https://static.retroachievements.org/assets/images/system/scd.png","Active":true,"IsGameSystem":true},{"ID":10,"Name":"32X","IconURL":"https://static.retroachievements.org/assets/images/system/32x.png","Active":true,"IsGameSystem":true},{"ID":11,"Name":"Master System","IconURL":"https://static.retroachievements.org/assets/images/system/sms.png","Active":true,"IsGameSystem":true},{"ID":12,"Name":"PlayStation","IconURL":"https://static.retroachievements.org/assets/images/system/ps1.png","Active":true,"IsGameSystem":true},{"ID":13,"Name":"Atari Lynx","IconURL":"https://static.retroachievements.org/assets/images/system/lynx.png","Active":true,"IsGameSystem":true},{"ID":14,"Name":"Neo Geo Pocket","IconURL":"https://static.retroachievements.org/assets/images/system/ngp.png","Active":true,"IsGameSystem":true},{"ID":15,"Name":"Game Gear","IconURL":"https://static.retroachievements.org/assets/images/system/gg.png","Active":true,"IsGameSystem":true},{"ID":16,"Name":"GameCube","IconURL":"https://static.retroachievements.org/assets/images/system/gc.png","Active":false,"IsGameSystem":true},{"ID":17,"Name":"Atari Jaguar","IconURL":"https://static.retroachievements.org/assets/images/system/jag.png","Active":true,"IsGameSystem":true},{"ID":18,"Name":"Nintendo DS","IconURL":"https://static.retroachievements.org/assets/images/system/ds.png","Active":true,"IsGameSystem":true},{"ID":19,"Name":"Wii","IconURL":"https://static.retroachievements.org/assets/images/system/wii.png","Active":false,"IsGameSystem":true},{"ID":20,"Name":"Wii U","IconURL":"https://static.retroachievements.org/assets/images/system/wiiu.png","Active":false,"IsGameSystem":true},{"ID":21,"Name":"PlayStation 2","IconURL":"https://static.retroachievements.org/assets/images/system/ps2.png","Active":true,"IsGameSystem":true},{"ID":22,"Name":"Xbox","IconURL":"https://static.retroachievements.org/assets/images/system/xbox.png","Active":false,"IsGameSystem":true},{"ID":23,"Name":"Magnavox Odyssey 2","IconURL":"https://static.retroachievements.org/assets/images/system/mo2.png","Active":true,"IsGameSystem":true},{"ID":24,"Name":"Pokemon Mini","IconURL":"https://static.retroachievements.org/assets/images/system/mini.png","Active":true,"IsGameSystem":true},{"ID":25,"Name":"Atari 2600","IconURL":"https://static.retroachievements.org/assets/images/system/2600.png","Active":true,"IsGameSystem":true},{"ID":26,"Name":"DOS","IconURL":"https://static.retroachievements.org/assets/images/system/dos.png","Active":false,"IsGameSystem":true},{"ID":27,"Name":"Arcade","IconURL":"https://static.retroachievements.org/assets/images/system/arc.png","Active":true,"IsGameSystem":true},{"ID":28,"Name":"Virtual Boy","IconURL":"https://static.retroachievements.org/assets/images/system/vb.png","Active":true,"IsGameSystem":true},{"ID":29,"Name":"MSX","IconURL":"https://static.retroachievements.org/assets/images/system/msx.png","Active":true,"IsGameSystem":true},{"ID":30,"Name":"Commodore 64","IconURL":"https://static.retroachievements.org/assets/images/system/c64.png","Active":false,"IsGameSystem":true},{"ID":31,"Name":"ZX81","IconURL":"https://static.retroachievements.org/assets/images/system/zx81.png","Active":false,"IsGameSystem":true},{"ID":32,"Name":"Oric","IconURL":"https://static.retroachievements.org/assets/images/system/oric.png","Active":false,"IsGameSystem":true},{"ID":33,"Name":"SG-1000","IconURL":"https://static.retroachievements.org/assets/images/system/sg1k.png","Active":true,"IsGameSystem":true},{"ID":34,"Name":"VIC-20","IconURL":"https://static.retroachievements.org/assets/images/system/vic-20.png","Active":false,"IsGameSystem":true},{"ID":35,"Name":"Amiga","IconURL":"https://static.retroachievements.org/assets/images/system/amiga.png","Active":false,"IsGameSystem":true},{"ID":36,"Name":"Atari ST","IconURL":"https://static.retroachievements.org/assets/images/system/ast.png","Active":false,"IsGameSystem":true},{"ID":37,"Name":"Amstrad CPC","IconURL":"https://static.retroachievements.org/assets/images/system/cpc.png","Active":true,"IsGameSystem":true},{"ID":38,"Name":"Apple II","IconURL":"https://static.retroachievements.org/assets/images/system/a2.png","Active":true,"IsGameSystem":true},{"ID":39,"Name":"Saturn","IconURL":"https://static.retroachievements.org/assets/images/system/sat.png","Active":true,"IsGameSystem":true},{"ID":40,"Name":"Dreamcast","IconURL":"https://static.retroachievements.org/assets/images/system/dc.png","Active":true,"IsGameSystem":true},{"ID":41,"Name":"PlayStation Portable","IconURL":"https://static.retroachievements.org/assets/images/system/psp.png","Active":true,"IsGameSystem":true},{"ID":42,"Name":"Philips CD-i","IconURL":"https://static.retroachievements.org/assets/images/system/cd-i.png","Active":false,"IsGameSystem":true},{"ID":43,"Name":"3DO Interactive Multiplayer","IconURL":"https://static.retroachievements.org/assets/images/system/3do.png","Active":true,"IsGameSystem":true},{"ID":44,"Name":"ColecoVision","IconURL":"https://static.retroachievements.org/assets/images/system/cv.png","Active":true,"IsGameSystem":true},{"ID":45,"Name":"Intellivision","IconURL":"https://static.retroachievements.org/assets/images/system/intv.png","Active":true,"IsGameSystem":true},{"ID":46,"Name":"Vectrex","IconURL":"https://static.retroachievements.org/assets/images/system/vect.png","Active":true,"IsGameSystem":true},{"ID":47,"Name":"PC-8000/8800","IconURL":"https://static.retroachievements.org/assets/images/system/8088.png","Active":true,"IsGameSystem":true},{"ID":48,"Name":"PC-9800","IconURL":"https://static.retroachievements.org/assets/images/system/9800.png","Active":false,"IsGameSystem":true},{"ID":49,"Name":"PC-FX","IconURL":"https://static.retroachievements.org/assets/images/system/pc-fx.png","Active":true,"IsGameSystem":true},{"ID":50,"Name":"Atari 5200","IconURL":"https://static.retroachievements.org/assets/images/system/5200.png","Active":false,"IsGameSystem":true},{"ID":51,"Name":"Atari 7800","IconURL":"https://static.retroachievements.org/assets/images/system/7800.png","Active":true,"IsGameSystem":true},{"ID":52,"Name":"Sharp X68000","IconURL":"https://static.retroachievements.org/assets/images/system/x68k.png","Active":false,"IsGameSystem":true},{"ID":53,"Name":"WonderSwan","IconURL":"https://static.retroachievements.org/assets/images/system/ws.png","Active":true,"IsGameSystem":true},{"ID":54,"Name":"Cassette Vision","IconURL":"https://static.retroachievements.org/assets/images/system/ecv.png","Active":false,"IsGameSystem":true},{"ID":55,"Name":"Super Cassette Vision","IconURL":"https://static.retroachievements.org/assets/images/system/escv.png","Active":false,"IsGameSystem":true},{"ID":56,"Name":"Neo Geo CD","IconURL":"https://static.retroachievements.org/assets/images/system/ngcd.png","Active":true,"IsGameSystem":true},{"ID":57,"Name":"Fairchild Channel F","IconURL":"https://static.retroachievements.org/assets/images/system/chf.png","Active":true,"IsGameSystem":true},{"ID":58,"Name":"FM Towns","IconURL":"https://static.retroachievements.org/assets/images/system/fm-towns.png","Active":false,"IsGameSystem":true},{"ID":59,"Name":"ZX Spectrum","IconURL":"https://static.retroachievements.org/assets/images/system/zxs.png","Active":false,"IsGameSystem":true},{"ID":60,"Name":"Game & Watch","IconURL":"https://static.retroachievements.org/assets/images/system/g&w.png","Active":false,"IsGameSystem":true},{"ID":61,"Name":"Nokia N-Gage","IconURL":"https://static.retroachievements.org/assets/images/system/n-gage.png","Active":false,"IsGameSystem":true},{"ID":62,"Name":"Nintendo 3DS","IconURL":"https://static.retroachievements.org/assets/images/system/3ds.png","Active":false,"IsGameSystem":true},{"ID":63,"Name":"Watara Supervision","IconURL":"https://static.retroachievements.org/assets/images/system/wsv.png","Active":true,"IsGameSystem":true},{"ID":64,"Name":"Sharp X1","IconURL":"https://static.retroachievements.org/assets/images/system/x1.png","Active":false,"IsGameSystem":true},{"ID":65,"Name":"TIC-80","IconURL":"https://static.retroachievements.org/assets/images/system/tic-80.png","Active":false,"IsGameSystem":true},{"ID":66,"Name":"Thomson TO8","IconURL":"https://static.retroachievements.org/assets/images/system/to8.png","Active":false,"IsGameSystem":true},{"ID":67,"Name":"PC-6000","IconURL":"https://static.retroachievements.org/assets/images/system/pc-6000.png","Active":false,"IsGameSystem":true},{"ID":68,"Name":"Sega Pico","IconURL":"https://static.retroachievements.org/assets/images/system/pico.png","Active":false,"IsGameSystem":true},{"ID":69,"Name":"Mega Duck","IconURL":"https://static.retroachievements.org/assets/images/system/duck.png","Active":true,"IsGameSystem":true},{"ID":70,"Name":"Zeebo","IconURL":"https://static.retroachievements.org/assets/images/system/zeebo.png","Active":false,"IsGameSystem":true},{"ID":71,"Name":"Arduboy","IconURL":"https://static.retroachievements.org/assets/images/system/ard.png","Active":true,"IsGameSystem":true},{"ID":72,"Name":"WASM-4","IconURL":"https://static.retroachievements.org/assets/images/system/wasm4.png","Active":true,"IsGameSystem":true},{"ID":73,"Name":"Arcadia 2001","IconURL":"https://static.retroachievements.org/assets/images/system/a2001.png","Active":true,"IsGameSystem":true},{"ID":74,"Name":"Interton VC 4000","IconURL":"https://static.retroachievements.org/assets/images/system/vc4000.png","Active":true,"IsGameSystem":true},{"ID":75,"Name":"Elektor TV Games Computer","IconURL":"https://static.retroachievements.org/assets/images/system/elek.png","Active":true,"IsGameSystem":true},{"ID":76,"Name":"PC Engine CD/TurboGrafx-CD","IconURL":"https://static.retroachievements.org/assets/images/system/pccd.png","Active":true,"IsGameSystem":true},{"ID":77,"Name":"Atari Jaguar CD","IconURL":"https://static.retroachievements.org/assets/images/system/jcd.png","Active":true,"IsGameSystem":true},{"ID":78,"Name":"Nintendo DSi","IconURL":"https://static.retroachievements.org/assets/images/system/dsi.png","Active":true,"IsGameSystem":true},{"ID":79,"Name":"TI-83","IconURL":"https://static.retroachievements.org/assets/images/system/ti-83.png","Active":false,"IsGameSystem":true},{"ID":80,"Name":"Uzebox","IconURL":"https://static.retroachievements.org/assets/images/system/uze.png","Active":true,"IsGameSystem":true},{"ID":102,"Name":"Standalone","IconURL":"https://static.retroachievements.org/assets/images/system/exe.png","Active":true,"IsGameSystem":true}]
"""
    init(){
        do {
            consoles = try JSONDecoder().decode([Console].self, from: consolesJSONString.data(using: .utf8)!)
        } catch {
            print("Error Generating Consoles Object!")
        }
    }
}
