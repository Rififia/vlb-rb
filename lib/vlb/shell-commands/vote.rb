require 'vlb/utils'

module VikiLinkBot
  class Shell

    def vote(m, input)
      if input.args.size < 2
        m.reply 'Il me faut un type de vote et une cible !'
        return
      end
      kind, targets = input.args.first.downcase.to_sym, input.args.drop(1)
      kinds = {
          admin: 'Vikidia:Administrateur',
          bureaucrate: 'Vikidia:Bureaucrate',
          contestation: "Vikidia:Contestation_du_statut_d'administrateur",
          pdd: 'Vikidia:Prise_de_décision',
          sa: 'Vikidia:Super_article/Élection'
      }
      unless kinds.key?(kind)
        guesses = Utils.guess(kind.to_s, kinds.keys)
        if guesses.size == 1
          kind = guesses.first.to_sym
        else
          m.reply(guesses.empty? ?
              "Désolé, je ne connais pas #{kind} mais #{kinds.keys.join(', ')} et leurs abbréviations." :
              "Je ne connais pas #{kind}, vouliez-vous plutôt dire #{Utils.join_multiple(guesses)} ?")
          return
        end
      end

      targets.uniq.each do |target|
        wiki = WikiFactory.instance.get('fr.vikidia.org')
        title = "#{kinds[kind]}/#{target}"
        begin
        content = wiki.api action: 'query', prop: 'revisions', titles: title, indexpageids: 1, rvlimit: 1, rvprop: 'content'
        rescue
          m.reply "Impossible de contacter #{wiki.domain} : #{$!}"
          next
        end
        begin
          content = content['query']['pages'][content['query']['pageids'][0]]['revisions'][0]['*']
        rescue NoMethodError
          m.reply "Ce vote n'a pas l'air d'exister. Pour le créer : #{wiki.article_url(title)}"
          next
        end
        votes = Hash.new(0)
        section = nil
        content.each_line do |line|
        ignored = ["{{cé}},{{conflit d'édition}}"]
        case line.downcase
            when /\A(?>=+\s*)(?:\{\{)?(Avis non pris en compte)/
              section = nil
            when /\A(?>[#*]\s*)\{\{?\b/
              votes[$1] += 1 if section 
        end
        if votes.values.reduce(0, &:+) == 0
            "Personne n'a encore voté, ou bien je ne sais pas reconnaitre les votes."
            votes.map { |k, v| "#{v} #{k}" }.join(', ') +
                " (#{(100 * votes['pour'] / votes.values.reduce(0, &:+).to_f).round(2)} % d'accord)"
        m.reply "#{comment} - #{wiki.article_url(title)}"
      end

    end

  end
end
