-- src/UI/UI.lua
return function(Context, Theme)
	local UIS = game:GetService("UserInputService")
	local CoreGui = game:GetService("CoreGui")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local CONFIG = Context.CONFIG or {}
	local State = Context.State or {}
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local UI_W = CONFIG.UI_W or 660
	local UI_H = CONFIG.UI_H or 460
	local TITLE_H = 28
	local TAB_H = 26
	local COL_GAP = 8
	local PAD = 8

	local function create(class, props, children)
		local inst = Instance.new(class)
		if props then
			for k, v in pairs(props) do
				pcall(function() inst[k] = v end)
			end
		end
		if children then
			for _, c in ipairs(children) do
				c.Parent = inst
			end
		end
		return inst
	end

	local function stroke(color, thick)
		return create("UIStroke", {
			Color = color or Theme.Border,
			Thickness = thick or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	end

	local function pad(t, b, l, r)
		if b == nil then
			return create("UIPadding", {
				PaddingTop = UDim.new(0, t),
				PaddingBottom = UDim.new(0, t),
				PaddingLeft = UDim.new(0, t),
				PaddingRight = UDim.new(0, t),
			})
		end
		return create("UIPadding", {
			PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or 0),
			PaddingLeft = UDim.new(0, l or 0),
			PaddingRight = UDim.new(0, r or 0),
		})
	end

	local _activeDrag = nil
	Connections.Add(UIS.InputChanged:Connect(function(input)
		if _activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			_activeDrag(input.Position.X)
		end
	end))
	Connections.Add(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			_activeDrag = nil
		end
	end))

	local UI = {}
	UI.__index = UI

	function UI.new(title)
		local self = setmetatable({}, UI)
		self.Tabs = {}
		self.ActiveTab = nil
		self._openDropdowns = {}
		self.Minimized = false
		self.Title = title or "B0Xaz"

		self.ScreenGui = create("ScreenGui", {
			Name = "B0XazUI",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			DisplayOrder = 999,
		})

		local parented = false
		pcall(function()
			if gethui then
				self.ScreenGui.Parent = gethui()
				parented = true
			end
		end)
		if not parented then
			pcall(function()
				self.ScreenGui.Parent = CoreGui
				parented = true
			end)
		end
		if not parented and LocalPlayer then
			self.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end

		self.Main = create("Frame", {
			Size = UDim2.new(0, UI_W, 0, UI_H),
			Position = UDim2.new(0.5, -UI_W / 2, 0.5, -UI_H / 2),
			BackgroundColor3 = Theme.Bg,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = self.ScreenGui,
		}, { stroke(Theme.Border, 1) })

		self.TitleBar = create("Frame", {
			Size = UDim2.new(1, 0, 0, TITLE_H),
			BackgroundColor3 = Theme.Side,
			BorderSizePixel = 0,
			Parent = self.Main,
		})
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.Border,
			BorderSizePixel = 0,
			Parent = self.TitleBar,
		})
		create("TextLabel", {
			Text = self.Title,
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Parent = self.TitleBar,
		})

		local closeBtn = create("TextButton", {
			Text = "x",
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = Theme.TextDim,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 28, 1, 0),
			Position = UDim2.new(1, -28, 0, 0),
			AutoButtonColor = false,
			Parent = self.TitleBar,
		})
		closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Theme.Danger end)
		closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Theme.TextDim end)
		closeBtn.MouseButton1Click:Connect(function()
			self.Main.Visible = false
			State.MenuVisible = false
		end)

		self.TabBar = create("Frame", {
			Size = UDim2.new(1, 0, 0, TAB_H),
			Position = UDim2.new(0, 0, 0, TITLE_H),
			BackgroundColor3 = Theme.Side,
			BorderSizePixel = 0,
			Parent = self.Main,
		})
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.BorderDim,
			BorderSizePixel = 0,
			Parent = self.TabBar,
		})

		-- Horizontal scrolling ensures all tabs are always visible/accessible
		self.TabList = create("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 4, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ClipsDescendants = true,
			Parent = self.TabBar,
		}, {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		self.Content = create("Frame", {
			Size = UDim2.new(1, 0, 1, -(TITLE_H + TAB_H)),
			Position = UDim2.new(0, 0, 0, TITLE_H + TAB_H),
			BackgroundTransparency = 1,
			Parent = self.Main,
		})
		self.PagesContainer = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = self.Content,
		})

		do
			local dragging, dragStart, startPos = false, nil, nil
			self.TitleBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = self.Main.Position
				end
			end)
			self.TitleBar.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			Connections.Add(UIS.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local d = input.Position - dragStart
					self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end))
		end

		self.NotifyContainer = create("Frame", {
			Size = UDim2.new(0, 300, 1, -20),
			Position = UDim2.new(1, -310, 0, 10),
			BackgroundTransparency = 1,
			Parent = self.ScreenGui,
		}, {
			create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		})

		return self
	end

	function UI:Destroy()
		pcall(function()
			if self.ScreenGui then self.ScreenGui:Destroy() end
		end)
	end

	function UI:RegisterDropdown(closeFn)
		table.insert(self._openDropdowns, closeFn)
	end

	function UI:CloseAllDropdownsExcept(exceptFn)
		for _, fn in ipairs(self._openDropdowns) do
			if fn ~= exceptFn then pcall(fn, false) end
		end
	end

	function UI:Notify(title, text, duration, color)
		local accent = color or Theme.Accent
		local notif = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			Parent = self.NotifyContainer,
		}, {
			stroke(accent, 1),
			pad(6, 6, 8, 8),
			create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("TextLabel", {
				Text = title or "Notification",
				Font = Enum.Font.Code,
				TextSize = 12,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				LayoutOrder = 1,
			}),
			create("TextLabel", {
				Text = text or "",
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}),
		})

		task.delay(duration or (CONFIG.NOTIFY_DEFAULT_TIME or 3.5), function()
			if notif and notif.Parent then
				pcall(function() notif:Destroy() end)
			end
		end)
	end

	function UI:SelectTab(tab)
		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			t.Button.TextColor3 = Theme.TextDim
			if t.Underline then t.Underline.Visible = false end
		end
		tab.Page.Visible = true
		tab.Button.TextColor3 = Theme.Text
		if tab.Underline then tab.Underline.Visible = true end
		self.ActiveTab = tab
		self:CloseAllDropdownsExcept(nil)
	end

	function UI:AddTab(name)
		local ui = self
		local tab = { Name = name, Sections = {}, UI = ui, _col = 0 }

		tab.Button = create("TextButton", {
			Text = name,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = Theme.TextDim,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, math.max(52, #name * 7 + 16), 1, 0),
			AutoButtonColor = false,
			Parent = self.TabList,
		})
		tab.Underline = create("Frame", {
			Size = UDim2.new(1, -8, 0, 2),
			Position = UDim2.new(0, 4, 1, -2),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tab.Button,
		})

		tab.Page = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = self.PagesContainer,
		})

		local colPad = PAD
		local gap = COL_GAP
		local scrollBarW = 3

		tab.LeftCol = create("ScrollingFrame", {
			Name = "LeftCol",
			Size = UDim2.new(0.5, -(colPad + gap / 2), 1, -colPad * 2),
			Position = UDim2.new(0, colPad, 0, colPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = scrollBarW,
			ScrollBarImageColor3 = Theme.AccentDark,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Parent = tab.Page,
		}, {
			create("UIListLayout", {
				Padding = UDim.new(0, gap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			pad(0, 4, 0, scrollBarW + 2),
		})

		tab.RightCol = create("ScrollingFrame", {
			Name = "RightCol",
			Size = UDim2.new(0.5, -(colPad + gap / 2), 1, -colPad * 2),
			Position = UDim2.new(0.5, gap / 2, 0, colPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = scrollBarW,
			ScrollBarImageColor3 = Theme.AccentDark,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Parent = tab.Page,
		}, {
			create("UIListLayout", {
				Padding = UDim.new(0, gap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			pad(0, 4, 0, scrollBarW + 2),
		})

		tab.Button.MouseEnter:Connect(function()
			if ui.ActiveTab ~= tab then tab.Button.TextColor3 = Theme.Text end
		end)
		tab.Button.MouseLeave:Connect(function()
			if ui.ActiveTab ~= tab then tab.Button.TextColor3 = Theme.TextDim end
		end)
		tab.Button.MouseButton1Click:Connect(function()
			ui:SelectTab(tab)
		end)

		table.insert(self.Tabs, tab)
		if not self.ActiveTab then
			self:SelectTab(tab)
		end

		function tab:AddSection(secName)
			local section = { Name = secName, Elements = {}, Tab = tab }

			tab._col = (tab._col % 2) + 1
			local parentCol = (tab._col == 1) and tab.LeftCol or tab.RightCol

			section.Frame = create("Frame", {
				BackgroundColor3 = Theme.Panel,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				Parent = parentCol,
			}, {
				stroke(Theme.Border, 1),
				create("UIListLayout", {
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})

			local titleBar = create("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = Theme.Side,
				BorderSizePixel = 0,
				LayoutOrder = 0,
				Parent = section.Frame,
			})
			create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Parent = titleBar,
			})
			create("TextLabel", {
				Text = "  " .. secName,
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = titleBar,
			})

			local body = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Parent = section.Frame,
			}, {
				create("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				pad(4, 6, 6, 6),
			})

			table.insert(tab.Sections, section)
			local rowOrder = 0

			local function newRow(elemName, h)
				rowOrder += 1
				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = rowOrder,
					Parent = body,
				}, {
					create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				local content = create("Frame", {
					Size = UDim2.new(1, 0, 0, h),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = row,
				})
				table.insert(section.Elements, { Container = row, Name = elemName })
				return row, content
			end

			function section:AddToggle(name, default, callback)
				local _, content = newRow(name, 22)
				local state = default and true or false

				local box = create("Frame", {
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(0, 2, 0.5, -6),
					BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
					BorderSizePixel = 0,
					Parent = content,
				}, { stroke(Theme.Border, 1) })

				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 20, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Parent = content,
				})

				local btn = create("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = content,
				})

				local function setState(v, silent)
					state = v and true or false
					box.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
					if not silent and callback then Utils.SafeCall(callback, state) end
				end

				btn.MouseButton1Click:Connect(function()
					setState(not state)
				end)

				return { Set = setState, Get = function() return state end }
			end

			function section:AddSlider(name, default, min, max, callback, suffix)
				local _, content = newRow(name, 36)
				suffix = suffix or ""

				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -50, 0, 14),
					Parent = content,
				})

				local valLabel = create("TextLabel", {
					Text = tostring(default) .. "/" .. tostring(max) .. suffix,
					Font = Enum.Font.Code,
					TextSize = 10,
					TextColor3 = Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -48, 0, 0),
					Size = UDim2.new(0, 46, 0, 14),
					Parent = content,
				})

				local track = create("Frame", {
					Size = UDim2.new(1, -4, 0, 4),
					Position = UDim2.new(0, 2, 0, 22),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = content,
				}, { stroke(Theme.BorderDim, 1) })

				local initRel = math.clamp((default - min) / math.max(max - min, 1e-6), 0, 1)
				local fill = create("Frame", {
					Size = UDim2.new(initRel, 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = track,
				})

				local value = default
				local function commit(rel, silent)
					rel = math.clamp(rel, 0, 1)
					value = math.floor(min + (max - min) * rel + 0.5)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					valLabel.Text = tostring(value) .. "/" .. tostring(max) .. suffix
					if not silent and callback then Utils.SafeCall(callback, value) end
				end

				local function updateFromX(x)
					commit((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						_activeDrag = updateFromX
						updateFromX(input.Position.X)
					end
				end)

				local hit = create("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 14),
					Position = UDim2.new(0, 0, 0, 16),
					Parent = content,
				})
				hit.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						_activeDrag = updateFromX
						updateFromX(input.Position.X)
					end
				end)

				return {
					Set = function(v, silent)
						local clamped = math.clamp(v, min, max)
						commit((clamped - min) / math.max(max - min, 1e-6), silent)
					end,
					Get = function() return value end,
				}
			end

			function section:AddButton(name, callback)
				local _, content = newRow(name, 24)
				local btn = create("TextButton", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.new(0, 0, 0, 2),
					AutoButtonColor = false,
					Parent = content,
				}, { stroke(Theme.Border, 1) })
				btn.MouseEnter:Connect(function()
					btn.BackgroundColor3 = Theme.ElemHover
					btn.TextColor3 = Theme.Accent
				end)
				btn.MouseLeave:Connect(function()
					btn.BackgroundColor3 = Theme.Elem
					btn.TextColor3 = Theme.Text
				end)
				btn.MouseButton1Click:Connect(function()
					if callback then Utils.SafeCall(callback) end
				end)
			end

			function section:AddDropdown(name, options, callback, default)
				local row, content = newRow(name, 40)
				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -4, 0, 14),
					Parent = content,
				})

				local currentOptions = table.clone(options or {})
				local selected = default or currentOptions[1] or ""
				local displayBtn = create("TextButton", {
					Text = (selected ~= "" and tostring(selected) or "None") .. "  v",
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.TextDim,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -4, 0, 18),
					Position = UDim2.new(0, 2, 0, 16),
					AutoButtonColor = false,
					Parent = content,
				}, { stroke(Theme.Border, 1) })

				local expansion = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Visible = false,
					Parent = row,
				})
				local listBox = create("ScrollingFrame", {
					Size = UDim2.new(1, -4, 1, 0),
					Position = UDim2.new(0, 2, 0, 0),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.AccentDark,
					Parent = expansion,
				}, {
					stroke(Theme.Border, 1),
					create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})

				local isOpen = false
				local function setOpen(open)
					isOpen = open
					if open then
						local h = math.min(#currentOptions, CONFIG.DROPDOWN_MAX_ROWS or 6) * (CONFIG.DROPDOWN_ROW_HEIGHT or 22) + 4
						expansion.Size = UDim2.new(1, 0, 0, math.max(h, 24))
						expansion.Visible = true
					else
						expansion.Visible = false
						expansion.Size = UDim2.new(1, 0, 0, 0)
					end
				end
				ui:RegisterDropdown(setOpen)

				local function rebuildOptions()
					for _, child in ipairs(listBox:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					local opts = #currentOptions > 0 and currentOptions or { "None" }
					for _, opt in ipairs(opts) do
						local optBtn = create("TextButton", {
							Text = "  " .. tostring(opt),
							Font = Enum.Font.Code,
							TextSize = 11,
							TextColor3 = Theme.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, CONFIG.DROPDOWN_ROW_HEIGHT or 22),
							AutoButtonColor = false,
							Parent = listBox,
						})
						optBtn.MouseEnter:Connect(function()
							optBtn.BackgroundTransparency = 0
							optBtn.BackgroundColor3 = Theme.ElemHover
						end)
						optBtn.MouseLeave:Connect(function()
							optBtn.BackgroundTransparency = 1
						end)
						optBtn.MouseButton1Click:Connect(function()
							if opt ~= "None" or #currentOptions > 0 then
								selected = opt
								displayBtn.Text = tostring(opt) .. "  v"
								setOpen(false)
								if callback then Utils.SafeCall(callback, opt) end
							end
						end)
					end
				end
				rebuildOptions()

				displayBtn.MouseButton1Click:Connect(function()
					ui:CloseAllDropdownsExcept(setOpen)
					setOpen(not isOpen)
				end)

				return {
					Set = function(v, silent)
						selected = v
						displayBtn.Text = tostring(v) .. "  v"
						if not silent and callback then Utils.SafeCall(callback, v) end
					end,
					Get = function() return selected end,
					Refresh = function(newOpts, preserve)
						currentOptions = table.clone(newOpts or {})
						if not preserve or not table.find(currentOptions, selected) then
							selected = currentOptions[1] or ""
							displayBtn.Text = (selected ~= "" and tostring(selected) or "None") .. "  v"
						end
						rebuildOptions()
					end,
					Close = function() setOpen(false) end,
				}
			end

			function section:AddTextbox(name, default, callback, placeholder)
				local _, content = newRow(name, 40)
				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -4, 0, 14),
					Parent = content,
				})
				local boxFrame = create("Frame", {
					Size = UDim2.new(1, -4, 0, 18),
					Position = UDim2.new(0, 2, 0, 16),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = content,
				}, { stroke(Theme.Border, 1) })
				local box = create("TextBox", {
					Text = default or "",
					PlaceholderText = placeholder or "",
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					PlaceholderColor3 = Theme.TextMuted,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 1, 0),
					Position = UDim2.new(0, 4, 0, 0),
					ClearTextOnFocus = false,
					Parent = boxFrame,
				})
				box.FocusLost:Connect(function(enter)
					if callback then Utils.SafeCall(callback, box.Text, enter) end
				end)
				return {
					Set = function(v) box.Text = tostring(v or "") end,
					Get = function() return box.Text end,
				}
			end

			function section:AddColorPicker(name, default, callback)
				local row, content = newRow(name, 22)
				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -30, 1, 0),
					Parent = content,
				})
				local currentColor = default or Color3.new(1, 1, 1)
				local swatch = create("TextButton", {
					Text = "",
					Size = UDim2.new(0, 16, 0, 12),
					Position = UDim2.new(1, -20, 0.5, -6),
					BackgroundColor3 = currentColor,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Parent = content,
				}, { stroke(Theme.Border, 1) })

				local presets = {
					Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
					Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 150, 50),
					Color3.fromRGB(255, 230, 50), Color3.fromRGB(50, 255, 80),
					Color3.fromRGB(0, 200, 220), Color3.fromRGB(80, 80, 255),
					Color3.fromRGB(200, 80, 255), Color3.fromRGB(255, 80, 180),
				}
				local expansion = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Visible = false,
					Parent = row,
				})
				local pickerBox = create("Frame", {
					Size = UDim2.new(1, -4, 1, 0),
					Position = UDim2.new(0, 2, 0, 0),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = expansion,
				}, {
					stroke(Theme.Border, 1),
					create("UIGridLayout", {
						CellSize = UDim2.new(0, 18, 0, 18),
						CellPadding = UDim2.new(0, 2, 0, 2),
					}),
					pad(4),
				})
				for _, c in ipairs(presets) do
					local pb = create("TextButton", {
						Text = "",
						BackgroundColor3 = c,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Parent = pickerBox,
					}, { stroke(Theme.BorderDim, 1) })
					pb.MouseButton1Click:Connect(function()
						currentColor = c
						swatch.BackgroundColor3 = c
						if callback then Utils.SafeCall(callback, c) end
					end)
				end
				local function setOpen(open)
					expansion.Visible = open
					expansion.Size = open and UDim2.new(1, 0, 0, 48) or UDim2.new(1, 0, 0, 0)
				end
				ui:RegisterDropdown(setOpen)
				swatch.MouseButton1Click:Connect(function()
					ui:CloseAllDropdownsExcept(setOpen)
					setOpen(not expansion.Visible)
				end)
				return {
					Set = function(c)
						currentColor = c
						swatch.BackgroundColor3 = c
					end,
					Get = function() return currentColor end,
				}
			end

			function section:AddKeybind(name, defaultKey, callback)
				local _, content = newRow(name, 22)
				create("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -64, 1, 0),
					Parent = content,
				})

				local currentKey = defaultKey

				local function getKeyDisplay(key)
					if not key then return "None" end
					if typeof(key) == "string" then return key:upper() end
					if typeof(key) == "EnumItem" then
						if key.EnumType == Enum.KeyCode then
							return key.Name
						elseif key.EnumType == Enum.UserInputType then
							local map = {
								[Enum.UserInputType.MouseButton1] = "MB1",
								[Enum.UserInputType.MouseButton2] = "MB2",
								[Enum.UserInputType.MouseButton3] = "MB3",
							}
							return map[key] or key.Name
						end
					end
					return "None"
				end

				local keyBtn = create("TextButton", {
					Text = getKeyDisplay(defaultKey),
					Font = Enum.Font.Code,
					TextSize = 10,
					TextColor3 = Theme.Text,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 56, 0, 16),
					Position = UDim2.new(1, -58, 0.5, -8),
					AutoButtonColor = false,
					Parent = content,
				}, { stroke(Theme.Border, 1) })

				local listening = false
				keyBtn.MouseButton1Click:Connect(function()
					listening = true
					keyBtn.Text = "..."
					keyBtn.TextColor3 = Theme.Accent
				end)

				Connections.Add(UIS.InputBegan:Connect(function(input, processed)
					if not listening then return end

					local bound = nil
					local finalize = false

					if input.UserInputType == Enum.UserInputType.Keyboard then
						if input.KeyCode == Enum.KeyCode.Escape then
							bound = nil
							finalize = true
						else
							bound = input.KeyCode
							finalize = true
						end
					elseif input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3 then
						bound = input.UserInputType
						finalize = true
					end

					if finalize then
						currentKey = bound
						keyBtn.Text = getKeyDisplay(bound)
						keyBtn.TextColor3 = Theme.Text
						listening = false
						if callback then Utils.SafeCall(callback, bound) end
					end
				end))

				return {
					Set = function(k)
						currentKey = k
						keyBtn.Text = getKeyDisplay(k)
					end,
					Get = function() return currentKey end,
				}
			end

			return section
		end

		return tab
	end

	return UI
end
