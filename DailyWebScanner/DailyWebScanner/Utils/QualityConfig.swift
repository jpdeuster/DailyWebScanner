import Foundation

final class QualityConfig {
    static let shared = QualityConfig()

    private let defaults = UserDefaults.standard

    // UserDefaults keys
    private let kQualityIndicators = "qualityIndicators"
    private let kLowQualityIndicators = "lowQualityIndicators"
    private let kMeaningfulPatterns = "meaningfulContentPatterns"
    private let kEmptyPatterns = "emptyContentPatterns"
    private let kExcludedUrlPatterns = "excludedUrlPatterns"

    private init() {
        // Seed defaults once if not present
        seedIfNeeded()
    }

    // MARK: - Public accessors
    var qualityIndicators: [String] { getArray(for: kQualityIndicators) }
    var lowQualityIndicators: [String] { getArray(for: kLowQualityIndicators) }
    var meaningfulContentPatterns: [String] { getArray(for: kMeaningfulPatterns) }
    var emptyContentPatterns: [String] { getArray(for: kEmptyPatterns) }
    var excludedUrlPatterns: [String] { getArray(for: kExcludedUrlPatterns) }

    func setQualityIndicators(_ values: [String]) { setArray(values, for: kQualityIndicators) }
    func setLowQualityIndicators(_ values: [String]) { setArray(values, for: kLowQualityIndicators) }
    func setMeaningfulContentPatterns(_ values: [String]) { setArray(values, for: kMeaningfulPatterns) }
    func setEmptyContentPatterns(_ values: [String]) { setArray(values, for: kEmptyPatterns) }
    func setExcludedUrlPatterns(_ values: [String]) { setArray(values, for: kExcludedUrlPatterns) }

    // MARK: - Internals
    private func getArray(for key: String) -> [String] {
        if let arr = defaults.array(forKey: key) as? [String] { return arr }
        return []
    }

    private func setArray(_ array: [String], for key: String) {
        // Normalize: trim, lowercase for matching consistency, remove empties, dedupe
        let normalized = Array(Set(array
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        ))
        defaults.set(normalized, forKey: key)
    }

    private func seedIfNeeded() {
        func setIfMissing(_ key: String, _ values: [String]) {
            if defaults.array(forKey: key) == nil { defaults.set(values, forKey: key) }
        }

        // Bring initial values from ContentQualityFilter defaults (snapshot)
        setIfMissing(kExcludedUrlPatterns, [
            "sitemap", "robots.txt", "privacy", "terms", "legal",
            ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
            ".zip", ".rar", ".exe", ".dmg", ".iso"
        ])

        setIfMissing(kQualityIndicators, [
            // EN
            "article","news","story","report","analysis","opinion","interview","review","tutorial","guide","explanation","breaking","update","investigation","feature","editorial",
            // DE
            "artikel","nachrichten","geschichte","bericht","analyse","meinung","bewertung","anleitung","leitfaden","erklärung","eilmeldung","aktualisierung","untersuchung","leitartikel",
            // FR
            "actualités","histoire","rapport","analyse","opinion","entretien","critique","tutoriel","guide","explication","urgent","mise à jour","enquête","article spécial","éditorial",
            // ES
            "artículo","noticias","historia","informe","análisis","opinión","entrevista","reseña","tutorial","guía","explicación","urgente","actualización","investigación","artículo especial","editorial",
            // IT
            "articolo","notizie","storia","rapporto","analisi","opinione","intervista","recensione","tutorial","guida","spiegazione","urgente","aggiornamento","indagine","articolo speciale","editoriale",
            // ZH
            "文章","新闻","故事","报告","分析","观点","采访","评论","教程","指南","解释","突发","更新","调查","专题","社论"
        ])

        setIfMissing(kLowQualityIndicators, [
            // EN
            "cookie","consent","banner","popup","modal","overlay","advertisement","sponsored","promo","offer","sale","login","signup","register","subscribe","newsletter","follow us","like us","share this","click here","read more",
            // DE
            "einverständnis","werbung","gesponsert","angebot","verkauf","anmelden","registrieren","abonnieren","newsletter","folgen sie uns","gefällt ihnen","teilen sie","hier klicken","mehr lesen",
            // FR
            "consentement","bannière","publicité","sponsorisé","offre","vente","connexion","inscription","s'abonner","newsletter","suivez-nous","aimez-nous","partagez","cliquez ici","lire la suite",
            // ES
            "consentimiento","publicidad","patrocinado","oferta","venta","iniciar sesión","registrarse","suscribirse","boletín","síguenos","me gusta","compartir","haz clic aquí","leer más",
            // IT
            "consenso","pubblicità","sponsorizzato","offerta","vendita","accedi","registrati","iscriviti","newsletter","seguici","mi piace","condividi","clicca qui","leggi di più",
            // ZH
            "同意","横幅","广告","赞助","优惠","销售","登录","注册","订阅","通讯","关注我们","点赞","分享","点击这里","阅读更多"
        ])

        setIfMissing(kMeaningfulPatterns, [
            // DE
            "berichtet","erklärt","analysiert","untersucht","zeigt","beschreibt","erzählt","informiert","berichtet über","nachrichten","meldung","entwicklung","situation","ereignis","artikel","analyse","kommentar","interview","reportage",
            // EN
            "reports","explains","analyzes","investigates","shows","describes","tells","informs","covers","discusses","news","update","development","situation","event","article","analysis","commentary","interview","feature","breaking","exclusive","investigation","report","story",
            // FR
            "rapporte","explique","analyse","enquête","montre","décrit","raconte","informe","couvre","discute","actualités","mise à jour","développement","situation","événement","article","analyse","commentaire","entretien","reportage",
            // ES
            "informa","explica","analiza","investiga","muestra","describe","cuenta","cubre","discute","noticias","actualización","desarrollo","situación","evento","artículo","análisis","comentario","entrevista","reportaje",
            // IT
            "riporta","spiega","analizza","indaga","mostra","descrive","racconta","informa","copre","discute","notizie","aggiornamento","sviluppo","situazione","evento","articolo","analisi","commento","intervista","reportage",
            // ZH
            "报道","解释","分析","调查","显示","描述","讲述","通知","覆盖","讨论","新闻","更新","发展","情况","事件","文章","分析","评论","采访","特写"
        ])

        setIfMissing(kEmptyPatterns, [
            // DE
            "folgen sie uns","teilen sie","gefällt ihnen","abonnieren","anmelden","registrieren","einloggen","konto erstellen","keine inhalte","nichts zu sehen","leer","placeholder","cookie","datenschutz","impressum","agb","widerruf",
            // EN
            "follow us","share this","like us","subscribe","sign up","register","log in","create account","no content","nothing to see","empty","placeholder","cookie","privacy","terms","legal","disclaimer","click here","read more","learn more","find out more",
            // FR
            "suivez-nous","partagez","aimez-nous","abonnez-vous","s'inscrire","s'enregistrer","se connecter","créer un compte","aucun contenu","rien à voir","vide","espace réservé","cookie","confidentialité","mentions légales","cgv",
            // ES
            "síguenos","comparte","gusta","suscribirse","registrarse","iniciar sesión","crear cuenta","sin contenido","nada que ver","vacío","marcador de posición","cookie","privacidad","términos","legal",
            // IT
            "seguici","condividi","mi piace","iscriviti","registrati","accedi","crea account","nessun contenuto","niente da vedere","vuoto","segnaposto","cookie","privacy","termini","legale",
            // ZH
            "关注我们","分享","点赞","订阅","注册","登录","创建账户","无内容","无内容可看","空白","占位符","cookie","隐私","条款","法律"
        ])
    }
}


