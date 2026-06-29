import Foundation

struct FlypyKey: Identifiable, Hashable {
    let id: String
    let initial: String?
    let finals: [String]
    let hint: String

    init(_ key: String, initial: String? = nil, finals: [String], hint: String) {
        self.id = key.uppercased()
        self.initial = initial
        self.finals = finals
        self.hint = hint
    }
}

enum FlypyLayout {
    static let keys: [FlypyKey] = [
        .init("q", initial: "q", finals: ["iu"], hint: "秋"),
        .init("w", initial: "w", finals: ["ei"], hint: "微"),
        .init("e", finals: ["e"], hint: "鹅"),
        .init("r", initial: "r", finals: ["uan", "üan", "er"], hint: "软"),
        .init("t", initial: "t", finals: ["üe", "ue"], hint: "月"),
        .init("y", initial: "y", finals: ["un", "ün"], hint: "云"),
        .init("u", initial: "sh", finals: ["u"], hint: "书"),
        .init("i", initial: "ch", finals: ["i"], hint: "吃"),
        .init("o", finals: ["o", "uo"], hint: "窝"),
        .init("p", initial: "p", finals: ["ie"], hint: "撇"),
        .init("a", finals: ["a"], hint: "啊"),
        .init("s", initial: "s", finals: ["ong", "iong"], hint: "松"),
        .init("d", initial: "d", finals: ["ai"], hint: "呆"),
        .init("f", initial: "f", finals: ["en"], hint: "分"),
        .init("g", initial: "g", finals: ["eng"], hint: "更"),
        .init("h", initial: "h", finals: ["ang"], hint: "航"),
        .init("j", initial: "j", finals: ["an"], hint: "安"),
        .init("k", initial: "k", finals: ["ing", "uai"], hint: "快"),
        .init("l", initial: "l", finals: ["iang", "uang"], hint: "亮"),
        .init("z", initial: "z", finals: ["ou"], hint: "走"),
        .init("x", initial: "x", finals: ["ia", "ua"], hint: "下"),
        .init("c", initial: "c", finals: ["ao"], hint: "草"),
        .init("v", initial: "zh", finals: ["ü", "ui"], hint: "追"),
        .init("b", initial: "b", finals: ["in"], hint: "宾"),
        .init("n", initial: "n", finals: ["iao"], hint: "鸟"),
        .init("m", initial: "m", finals: ["ian"], hint: "眠")
    ]

    static func key(for id: String) -> FlypyKey? {
        keys.first { $0.id.lowercased() == id.lowercased() }
    }

    static let initials: [String: String] = {
        var result = Dictionary(uniqueKeysWithValues: keys.compactMap { key in
            key.initial.map { ($0, key.id.lowercased()) }
        })

        for letter in "bcdfghjklmnpqrstvwxyz" {
            let key = String(letter)
            result[key] = result[key] ?? key
        }

        result["zh"] = "v"
        result["ch"] = "i"
        result["sh"] = "u"
        return result
    }()

    static let finals: [String: String] = {
        var result: [String: String] = [:]
        for key in keys {
            for final in key.finals {
                result[normalize(final)] = key.id.lowercased()
            }
        }
        result["v"] = "v"
        result["ve"] = "t"
        result["van"] = "r"
        result["vn"] = "y"
        return result
    }()

    static func code(for rawPinyin: String) -> String? {
        let pinyin = normalize(rawPinyin)

        if let finalKey = finals[pinyin], isZeroInitialFinal(pinyin) {
            if pinyin.count == 1 {
                return "\(pinyin)\(finalKey)"
            }
            if pinyin.count == 2 {
                return pinyin
            }
            return "\(pinyin.prefix(1))\(finalKey)"
        }

        let possibleInitials = ["zh", "ch", "sh"] + initials.keys.filter { $0.count == 1 }.sorted { $0.count > $1.count }

        for initial in possibleInitials where pinyin.hasPrefix(initial) {
            var final = String(pinyin.dropFirst(initial.count))
            if ["j", "q", "x", "y"].contains(initial), final == "u" {
                final = "v"
            }

            guard !final.isEmpty, let initialKey = initials[initial], let finalKey = finals[final] else {
                continue
            }
            return initialKey + finalKey
        }

        return nil
    }

    static func final(for rawPinyin: String) -> String? {
        let pinyin = normalize(rawPinyin)

        if finals[pinyin] != nil, isZeroInitialFinal(pinyin) {
            return pinyin
        }

        let possibleInitials = ["zh", "ch", "sh"] + initials.keys.filter { $0.count == 1 }.sorted { $0.count > $1.count }

        for initial in possibleInitials where pinyin.hasPrefix(initial) {
            var final = String(pinyin.dropFirst(initial.count))
            if ["j", "q", "x", "y"].contains(initial), final == "u" {
                final = "v"
            }

            if finals[final] != nil {
                return final
            }
        }

        return nil
    }

    private static func isZeroInitialFinal(_ text: String) -> Bool {
        finals[text] != nil && !text.hasPrefix("zh") && !text.hasPrefix("ch") && !text.hasPrefix("sh")
    }

    static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "ü", with: "v")
            .replacingOccurrences(of: "u:", with: "v")
    }

    static func display(_ text: String) -> String {
        text.replacingOccurrences(of: "v", with: "ü")
    }
}

struct PracticeItem: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let pinyin: String
    let code: String

    init(word: String, pinyin: String, code: String? = nil) {
        self.word = word
        self.pinyin = pinyin
        self.code = code ?? FlypyLayout.code(for: pinyin) ?? ""
    }

    static func random() -> PracticeItem {
        FlypyLayout.examples.randomElement() ?? .init(word: "今", pinyin: "jin", code: "jb")
    }
}

extension FlypyLayout {
    static let examples: [PracticeItem] = [
        .init(word: "今", pinyin: "jin", code: "jb"),
        .init(word: "见", pinyin: "jian", code: "jm"),
        .init(word: "京", pinyin: "jing", code: "jk"),
        .init(word: "江", pinyin: "jiang", code: "jl"),
        .init(word: "交", pinyin: "jiao", code: "jn"),
        .init(word: "中", pinyin: "zhong", code: "vs"),
        .init(word: "双", pinyin: "shuang", code: "ul"),
        .init(word: "国", pinyin: "guo", code: "go"),
        .init(word: "软", pinyin: "ruan", code: "rr"),
        .init(word: "云", pinyin: "yun", code: "yy"),
        .init(word: "鸟", pinyin: "niao", code: "nn"),
        .init(word: "眠", pinyin: "mian", code: "mm"),
        .init(word: "航", pinyin: "hang", code: "hh"),
        .init(word: "更", pinyin: "geng", code: "gg"),
        .init(word: "分", pinyin: "fen", code: "ff"),
        .init(word: "草", pinyin: "cao", code: "cc"),
        .init(word: "追", pinyin: "zhui", code: "vv"),
        .init(word: "下", pinyin: "xia", code: "xx"),
        .init(word: "昂", pinyin: "ang", code: "ah"),
        .init(word: "爱", pinyin: "ai", code: "ai"),
        .init(word: "的", pinyin: "de"),
        .init(word: "一", pinyin: "yi"),
        .init(word: "是", pinyin: "shi"),
        .init(word: "不", pinyin: "bu"),
        .init(word: "了", pinyin: "le"),
        .init(word: "在", pinyin: "zai"),
        .init(word: "人", pinyin: "ren"),
        .init(word: "有", pinyin: "you"),
        .init(word: "我", pinyin: "wo"),
        .init(word: "他", pinyin: "ta"),
        .init(word: "这", pinyin: "zhe"),
        .init(word: "大", pinyin: "da"),
        .init(word: "来", pinyin: "lai"),
        .init(word: "上", pinyin: "shang"),
        .init(word: "个", pinyin: "ge"),
        .init(word: "到", pinyin: "dao"),
        .init(word: "说", pinyin: "shuo"),
        .init(word: "们", pinyin: "men"),
        .init(word: "为", pinyin: "wei"),
        .init(word: "子", pinyin: "zi"),
        .init(word: "和", pinyin: "he"),
        .init(word: "你", pinyin: "ni"),
        .init(word: "地", pinyin: "di"),
        .init(word: "出", pinyin: "chu"),
        .init(word: "道", pinyin: "dao"),
        .init(word: "也", pinyin: "ye"),
        .init(word: "时", pinyin: "shi"),
        .init(word: "年", pinyin: "nian"),
        .init(word: "得", pinyin: "de"),
        .init(word: "就", pinyin: "jiu"),
        .init(word: "那", pinyin: "na"),
        .init(word: "要", pinyin: "yao"),
        .init(word: "下", pinyin: "xia"),
        .init(word: "以", pinyin: "yi"),
        .init(word: "生", pinyin: "sheng"),
        .init(word: "会", pinyin: "hui"),
        .init(word: "自", pinyin: "zi"),
        .init(word: "着", pinyin: "zhe"),
        .init(word: "去", pinyin: "qu"),
        .init(word: "之", pinyin: "zhi"),
        .init(word: "过", pinyin: "guo"),
        .init(word: "家", pinyin: "jia"),
        .init(word: "学", pinyin: "xue"),
        .init(word: "对", pinyin: "dui"),
        .init(word: "可", pinyin: "ke"),
        .init(word: "她", pinyin: "ta"),
        .init(word: "里", pinyin: "li"),
        .init(word: "后", pinyin: "hou"),
        .init(word: "小", pinyin: "xiao"),
        .init(word: "么", pinyin: "me"),
        .init(word: "心", pinyin: "xin"),
        .init(word: "多", pinyin: "duo"),
        .init(word: "天", pinyin: "tian"),
        .init(word: "而", pinyin: "er"),
        .init(word: "能", pinyin: "neng"),
        .init(word: "好", pinyin: "hao"),
        .init(word: "都", pinyin: "dou"),
        .init(word: "然", pinyin: "ran"),
        .init(word: "没", pinyin: "mei"),
        .init(word: "日", pinyin: "ri"),
        .init(word: "于", pinyin: "yu"),
        .init(word: "起", pinyin: "qi"),
        .init(word: "还", pinyin: "hai"),
        .init(word: "发", pinyin: "fa"),
        .init(word: "成", pinyin: "cheng"),
        .init(word: "事", pinyin: "shi"),
        .init(word: "只", pinyin: "zhi"),
        .init(word: "作", pinyin: "zuo"),
        .init(word: "当", pinyin: "dang"),
        .init(word: "想", pinyin: "xiang"),
        .init(word: "看", pinyin: "kan"),
        .init(word: "文", pinyin: "wen"),
        .init(word: "无", pinyin: "wu"),
        .init(word: "开", pinyin: "kai"),
        .init(word: "手", pinyin: "shou"),
        .init(word: "十", pinyin: "shi"),
        .init(word: "用", pinyin: "yong"),
        .init(word: "主", pinyin: "zhu"),
        .init(word: "行", pinyin: "xing"),
        .init(word: "方", pinyin: "fang"),
        .init(word: "又", pinyin: "you"),
        .init(word: "如", pinyin: "ru"),
        .init(word: "前", pinyin: "qian"),
        .init(word: "所", pinyin: "suo"),
        .init(word: "本", pinyin: "ben"),
        .init(word: "经", pinyin: "jing"),
        .init(word: "头", pinyin: "tou"),
        .init(word: "面", pinyin: "mian"),
        .init(word: "公", pinyin: "gong"),
        .init(word: "同", pinyin: "tong"),
        .init(word: "三", pinyin: "san"),
        .init(word: "已", pinyin: "yi"),
        .init(word: "老", pinyin: "lao"),
        .init(word: "从", pinyin: "cong"),
        .init(word: "动", pinyin: "dong"),
        .init(word: "两", pinyin: "liang"),
        .init(word: "长", pinyin: "chang"),
        .init(word: "知", pinyin: "zhi"),
        .init(word: "民", pinyin: "min"),
        .init(word: "样", pinyin: "yang"),
        .init(word: "现", pinyin: "xian"),
        .init(word: "点", pinyin: "dian"),
        .init(word: "月", pinyin: "yue"),
        .init(word: "定", pinyin: "ding"),
        .init(word: "情", pinyin: "qing"),
        .init(word: "最", pinyin: "zui"),
        .init(word: "鱼", pinyin: "yu"),
        .init(word: "句", pinyin: "ju"),
        .init(word: "区", pinyin: "qu"),
        .init(word: "需", pinyin: "xu")
    ]
}
