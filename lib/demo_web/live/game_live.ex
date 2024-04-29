defmodule DemoWeb.GameLive do
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    piece_to_move = :red
    pps = [red: {3, 1}, green: {3, 3}]

    socket =
      assign(socket, piece_to_move: piece_to_move, piece_positions: pps)

    {:ok, socket}
  end

  def handle_event(
        "recv_piece",
        %{"draggableId" => piece_id, "toId" => to_id},
        socket
      ) do
    piece_moved = pid_be(piece_id)

    pps =
      List.keyreplace(
        socket.assigns.piece_positions,
        piece_moved,
        0,
        {piece_moved, id_to_xy(to_id)}
      )

    socket =
      assign(socket, piece_to_move: toggle_piece_to_move(piece_moved), piece_positions: pps)

    {
      :noreply,
      socket
    }
  end

  def id_to_xy(cxy) do
    [_, x, y] = String.split(cxy, "-")
    {String.to_integer(x), String.to_integer(y)}
  end

  def render(assigns) do
    ~H"""
    <div class="game-container">
      <div class="game-board">
        <table>
          <%= for row <- 1..3 do %>
            <tr>
              <%= for col <- 1..3 do %>
                <.board_cell
                  row={row}
                  col={col}
                  is_drop_site={is_drop_site(row, col, @piece_to_move, @piece_positions)}
                  piece_id={piece_at_position(row, col, @piece_positions) |> pid_fe}
                  mover={mover_at_position(row, col, @piece_to_move, @piece_positions)}
                />
              <% end %>
            </tr>
          <% end %>
        </table>
      </div>
    </div>
    """
  end

  def is_drop_site(row, col, piece_to_move, piece_positions) do
    {_, src_pos} = List.keyfind(piece_positions, piece_to_move, 0)

    case in_range({row, col}, src_pos) do
      true -> "Drop"
      false -> nil
    end
  end

  def in_range({x, y}, {x, y}) do
    false
  end

  def in_range({x1, y1}, {x2, y2}) do
    abs(x1 - x2) < 2 and abs(y1 - y2) < 2
  end

  def piece_at_position(row, col, piece_positions) do
    case List.keyfind(piece_positions, {row, col}, 1) do
      nil -> nil
      {pid, _} -> pid
    end
  end

  def pid_fe(:red), do: "piece-red"
  def pid_fe(:green), do: "piece-green"
  def pid_fe(nil), do: nil

  def pid_be("piece-red"), do: :red
  def pid_be("piece-green"), do: :green

  def toggle_piece_to_move(:red), do: :green
  def toggle_piece_to_move(:green), do: :red

  def mover_at_position(row, col, piece_to_move, piece_positions) do
    case piece_at_position(row, col, piece_positions) do
      nil -> false
      pid -> pid == piece_to_move
    end
  end

  def board_cell(assigns) do
    ~H"""
    <td id={"cell-#{@row}-#{@col}"} phx-hook={@is_drop_site}>
      <%= if @mover do %>
        <div class="piece" id={@piece_id} draggable="true" ondragstart="dragStart(event)"></div>
      <% else %>
        <%= if @piece_id do %>
          <div class="piece" id={@piece_id}></div>
        <% end %>
      <% end %>
    </td>
    """
  end
end
