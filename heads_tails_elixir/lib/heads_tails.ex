defmodule HeadsTails do
  @moduledoc """
  Documentation for HeadsTails.
  """

  @doc """
  Hello world.

  ## Examples

      iex> HeadsTails.hello
      :world

  """
  def hello do
    :world
  end
end

defmodule HeadsTails.Player do
  defstruct original_guess: :heads,
            current_guess: :heads,
            strategy: :random,
            losses_left: 5,
            additional_losses: 0,
            wins: 0

  @default_losses 5

  def new(strategy, initial_guess, additional_losses \\ 0) do
    %HeadsTails.Player{
      original_guess: initial_guess,
      current_guess: initial_guess,
      strategy: strategy,
      losses_left: @default_losses + additional_losses,
      additional_losses: additional_losses
    }
  end

  def reset(%HeadsTails.Player{} = player) do
    wins =
      case player.losses_left do
        0 -> player.wins
        _ -> player.wins + 1
      end

    %{
      player
      | :losses_left => @default_losses + player.additional_losses,
        :current_guess => player.original_guess,
        :wins => wins
    }
  end

  defp number_to_coin_side(one_or_zero) do
    case one_or_zero do
      0 -> :heads
      1 -> :tails
    end
  end

  defp random_coin_side() do
    [0..1]
    |> Enum.random()
    |> number_to_coin_side()
  end

  def retry_toss(%HeadsTails.Player{} = player) do
    %{player | :losses_left => player.losses_left + 1}
  end

  defp toggle_guess(%HeadsTails.Player{current_guess: :heads} = player) do
    %{player | :current_guess => :tails}
  end

  defp toggle_guess(%HeadsTails.Player{current_guess: :tails} = player) do
    %{player | :current_guess => :heads}
  end

  def strategize(%HeadsTails.Player{strategy: :random} = player, _) do
    %{player | :current_guess => random_coin_side()}
  end

  def strategize(%HeadsTails.Player{strategy: :alternating} = player, _) do
    player |> toggle_guess()
  end

  def strategize(%HeadsTails.Player{strategy: :hold_on_win_switch_on_loss} = player, lost) do
    if lost do
      player |> toggle_guess()
    end
  end

  def strategize(%HeadsTails.Player{strategy: :hold_on_loss_switch_on_win} = player, lost) do
    if not lost do
      player |> toggle_guess()
    end
  end

  def strategize(%HeadsTails.Player{strategy: :always_heads} = player, _) do
    %{player | :current_guess => :heads}
  end

  def strategize(%HeadsTails.Player{strategy: :always_tails} = player, _) do
    %{player | :current_guess => :tails}
  end

  def evalueate_coin_toss(%HeadsTails.Player{current_guess: guess} = player, toss_result) do
  end
end
