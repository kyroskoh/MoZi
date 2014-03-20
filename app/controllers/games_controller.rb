class GamesController < ApplicationController
  def index
    Game.refresh
    @games = Game.all[0...10]
  end
  
  def show
    @game = Game.find(params[:id])
    @streams = @game.ordered_stream_list
  end
  
  def favorite
    game = Game.find(params[:id])
    game.game_favorites.create(user_id: current_user.id)
    flash[:notice] = "#{game.name} added to your favorites!"
    redirect_to games_path
  end
end