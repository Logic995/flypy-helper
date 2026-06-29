import Foundation

enum PracticeMode: String, CaseIterable, Identifiable {
    case character = "字"
    case phrase = "词"
    case sentence = "句"
    case article = "文"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .character: "随机字"
        case .phrase: "词组"
        case .sentence: "句子"
        case .article: "短文"
        }
    }
}

struct PracticeUnit: Identifiable, Hashable {
    let id = UUID()
    let mode: PracticeMode
    let title: String
    let text: String
    let pinyins: [String]

    var cleanText: String {
        PracticeContent.clean(text)
    }

    var finals: [String] {
        pinyins.compactMap { FlypyLayout.final(for: $0) }
    }

    var codes: [String] {
        pinyins.compactMap { FlypyLayout.code(for: $0) }
    }

    var hint: String {
        zip(PracticeContent.chineseCharacters(in: text), pinyins)
            .prefix(mode == .article ? 28 : 18)
            .map { char, pinyin in
                let code = FlypyLayout.code(for: pinyin) ?? "?"
                return "\(char) \(code)"
            }
            .joined(separator: "  ")
    }

    func errorFinals(for rawAnswer: String) -> [String] {
        let target = Array(cleanText)
        let answer = Array(PracticeContent.clean(rawAnswer))
        let limit = max(target.count, answer.count)
        var result: [String] = []

        for index in 0..<limit {
            let expected = index < target.count ? target[index] : nil
            let actual = index < answer.count ? answer[index] : nil

            if expected != actual, index < pinyins.count, let final = FlypyLayout.final(for: pinyins[index]) {
                result.append(final)
            }

            if result.count >= 10 {
                break
            }
        }

        return result
    }
}

enum PracticeContent {
    static func units(for mode: PracticeMode) -> [PracticeUnit] {
        switch mode {
        case .character:
            characterUnits
        case .phrase:
            phraseUnits
        case .sentence:
            sentenceUnits
        case .article:
            articleUnits
        }
    }

    static func pick(mode: PracticeMode, errorWeights: [String: Int]) -> PracticeUnit {
        let pool = units(for: mode)
        guard let fallback = pool.randomElement() else {
            return PracticeUnit(mode: .character, title: "今", text: "今", pinyins: ["jin"])
        }

        let weightedPool = pool.map { unit -> (PracticeUnit, Double) in
            let uniqueFinals = Set(unit.finals)
            let weightedMistakes = uniqueFinals.reduce(0) { partial, final in
                partial + min(errorWeights[final] ?? 0, 12)
            }

            let modeScale: Double = switch mode {
            case .character: 0.85
            case .phrase: 0.65
            case .sentence: 0.42
            case .article: 0.28
            }

            let randomJitter = Double.random(in: 0.75...1.25)
            let boost = min(Double(weightedMistakes) * modeScale, 9)
            return (unit, (1 + boost) * randomJitter)
        }

        let total = weightedPool.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return fallback }

        var cursor = Double.random(in: 0..<total)
        for (unit, weight) in weightedPool {
            cursor -= weight
            if cursor <= 0 {
                return unit
            }
        }

        return fallback
    }

    static func clean(_ text: String) -> String {
        String(text.filter { char in
            char.unicodeScalars.contains { scalar in
                (0x4E00...0x9FFF).contains(Int(scalar.value))
            }
        })
    }

    static func chineseCharacters(in text: String) -> [String] {
        clean(text).map(String.init)
    }

    private static let characterUnits: [PracticeUnit] = {
        var seen = Set<String>()
        return FlypyLayout.examples.compactMap { item in
            guard !seen.contains(item.word) else { return nil }
            seen.insert(item.word)
            return PracticeUnit(mode: .character, title: "随机字", text: item.word, pinyins: [item.pinyin])
        }
    }()

    private static let phraseUnits: [PracticeUnit] = [
        phrase("今天", "jin tian"),
        phrase("明天", "ming tian"),
        phrase("时间", "shi jian"),
        phrase("问题", "wen ti"),
        phrase("现在", "xian zai"),
        phrase("如果", "ru guo"),
        phrase("因为", "yin wei"),
        phrase("所以", "suo yi"),
        phrase("可以", "ke yi"),
        phrase("朋友", "peng you"),
        phrase("学习", "xue xi"),
        phrase("工作", "gong zuo"),
        phrase("生活", "sheng huo"),
        phrase("事情", "shi qing"),
        phrase("方向", "fang xiang"),
        phrase("声音", "sheng yin"),
        phrase("漂亮", "piao liang"),
        phrase("想象", "xiang xiang"),
        phrase("重要", "zhong yao"),
        phrase("选择", "xuan ze"),
        phrase("继续", "ji xu"),
        phrase("需要", "xu yao"),
        phrase("发现", "fa xian"),
        phrase("经过", "jing guo"),
        phrase("开始", "kai shi"),
        phrase("结束", "jie shu"),
        phrase("世界", "shi jie"),
        phrase("中国", "zhong guo"),
        phrase("文章", "wen zhang"),
        phrase("练习", "lian xi"),
        phrase("键位", "jian wei"),
        phrase("双拼", "shuang pin"),
        phrase("小鹤", "xiao he"),
        phrase("输入", "shu ru"),
        phrase("准确", "zhun que"),
        phrase("速度", "su du"),
        phrase("记忆", "ji yi"),
        phrase("注意", "zhu yi"),
        phrase("习惯", "xi guan"),
        phrase("每天", "mei tian"),
        phrase("认真", "ren zhen"),
        phrase("自然", "zi ran"),
        phrase("清楚", "qing chu"),
        phrase("以后", "yi hou"),
        phrase("容易", "rong yi"),
        phrase("感觉", "gan jue"),
        phrase("键盘", "jian pan"),
        phrase("熟练", "shu lian"),
        phrase("错误", "cuo wu"),
        phrase("提示", "ti shi")
    ]

    private static let sentenceUnits: [PracticeUnit] = [
        sentence("今天开始练习小鹤双拼。", "jin tian kai shi lian xi xiao he shuang pin"),
        sentence("速度慢一点也没有关系。", "su du man yi dian ye mei you guan xi"),
        sentence("先保证准确，再慢慢提高速度。", "xian bao zheng zhun que zai man man ti gao su du"),
        sentence("遇到不会的键位，就看一眼提示。", "yu dao bu hui de jian wei jiu kan yi yan ti shi"),
        sentence("每天练十分钟，很快就会顺手。", "mei tian lian shi fen zhong hen kuai jiu hui shun shou"),
        sentence("输入法不是负担，而是工具。", "shu ru fa bu shi fu dan er shi gong ju"),
        sentence("把错误留给练习，把熟练交给时间。", "ba cuo wu liu gei lian xi ba shu lian jiao gei shi jian"),
        sentence("我正在学习一种新的输入方式。", "wo zheng zai xue xi yi zhong xin de shu ru fang shi"),
        sentence("熟悉之后，双拼会变得很自然。", "shu xi zhi hou shuang pin hui bian de hen zi ran"),
        sentence("不要急，肌肉记忆需要一点耐心。", "bu yao ji ji rou ji yi xu yao yi dian nai xin"),
        sentence("先看清目标，再把句子完整输入。", "xian kan qing mu biao zai ba ju zi wan zheng shu ru"),
        sentence("错得越多的韵母，后面越容易出现。", "cuo de yue duo de yun mu hou mian yue rong yi chu xian")
    ]

    private static let articleUnits: [PracticeUnit] = [
        article(
            "静夜思",
            "床前明月光，疑是地上霜。举头望明月，低头思故乡。",
            "chuang qian ming yue guang yi shi di shang shuang ju tou wang ming yue di tou si gu xiang"
        ),
        article(
            "春晓",
            "春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。",
            "chun mian bu jue xiao chu chu wen ti niao ye lai feng yu sheng hua luo zhi duo shao"
        ),
        article(
            "登鹳雀楼",
            "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。",
            "bai ri yi shan jin huang he ru hai liu yu qiong qian li mu geng shang yi ceng lou"
        ),
        article(
            "陋室铭（节选）",
            "山不在高，有仙则名。水不在深，有龙则灵。斯是陋室，惟吾德馨。苔痕上阶绿，草色入帘青。",
            "shan bu zai gao you xian ze ming shui bu zai shen you long ze ling si shi lou shi wei wu de xin tai hen shang jie lv cao se ru lian qing"
        ),
        article(
            "道德经（节选）",
            "道可道，非常道。名可名，非常名。无名天地之始，有名万物之母。",
            "dao ke dao fei chang dao ming ke ming fei chang ming wu ming tian di zhi shi you ming wan wu zhi mu"
        ),
        article(
            "爱莲说（节选）",
            "予独爱莲之出淤泥而不染，濯清涟而不妖。",
            "yu du ai lian zhi chu yu ni er bu ran zhuo qing lian er bu yao"
        )
    ]

    private static func phrase(_ text: String, _ pinyin: String) -> PracticeUnit {
        PracticeUnit(mode: .phrase, title: "词组", text: text, pinyins: pinyin.split(separator: " ").map(String.init))
    }

    private static func sentence(_ text: String, _ pinyin: String) -> PracticeUnit {
        PracticeUnit(mode: .sentence, title: "句子", text: text, pinyins: pinyin.split(separator: " ").map(String.init))
    }

    private static func article(_ title: String, _ text: String, _ pinyin: String) -> PracticeUnit {
        PracticeUnit(mode: .article, title: title, text: text, pinyins: pinyin.split(separator: " ").map(String.init))
    }
}
