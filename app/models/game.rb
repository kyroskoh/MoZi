# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  logo       :string(255)
#  box        :string(255)
#  viewers    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Game < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  default_scope order('viewers DESC')
  
  paginates_per 10
  
  has_many :game_favorites,
    class_name: "GameFavorite",
    foreign_key: :game_id
  
  has_many :fans,
    through: :game_favorites,
    source: :user
  
  def self.refresh
    Game.update_all("viewers = 0")
    @games = Twitch.new().getTopGames(limit: 100)[:body]["top"]
    # new_games = []
    connection = PG.connect(dbname: 'mozi_dev_db')
    Upsert.batch(connection, :games) do |upsert|
      @games.each do |game|
        # updated_games << Game.new(name: game["game"]["name"].gsub("'", ""),
        #                           logo: game["game"]["logo"]["large"],
        #                           box:  game["game"]["box"]["large"],
        #                           viewers: game["viewers"])
        # if current_game = Game.find_by(name: game["game"]["name"])
        #   current_game.update_attributes(viewers: game["viewers"])
        # else
        #   new_games << Game.new(name: game["game"]["name"].gsub("'", ""),
        #                         logo: game["game"]["logo"]["large"],
        #                         box:  game["game"]["box"]["large"],
        #                         viewers: game["viewers"])
        # end
        upsert.row({name: game["game"]["name"].gsub("'", "")},
                    logo: game["game"]["logo"]["large"],
                    box:  game["game"]["box"]["large"],
                    viewers: game["viewers"]).to_i
      end
    end
    # Game.import new_games
  end
  
  def ordered_stream_list
    Stream.fetch_by_game(self.name)
    Stream.where(game: self.name).sort do |stream1, stream2|
      stream2.viewers <=> stream1.viewers
    end.slice(0...25)
  end
  
  def self.top_games(page)
    Rails.cache.fetch("top-games", expires_in: 10.seconds) do
      games = force_top_games(page)
      Kaminari::PaginatableArray.new(games.to_a,
                                     limit: games.limit_value,
                                     offset: games.offset_value,
                                     total_count: games.total_count)
    end
  end
  
  def self.force_top_games(current_page)
    Game.page(current_page)
  end
end
