###

ownCloud - News

@author Bernhard Posselt
@copyright 2012 Bernhard Posselt nukeawhale@gmail.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE
License as published by the Free Software Foundation; either
version 3 of the License, or any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU AFFERO GENERAL PUBLIC LICENSE for more details.

You should have received a copy of the GNU Affero General Public
License along with this library.  If not, see <http://www.gnu.org/licenses/>.

###


angular.module('News').factory '_FeedController', ->

	class FeedController

		constructor: (@$scope, @_folderModel, @_feedModel, @_active,
					@_showAll, @_feedType, @_starredCount, @_persistence,
					@_itemModel) ->

			# bind internal stuff to scope
			@$scope.feeds = @_feedModel.getAll()
			@$scope.folders = @_folderModel.getAll()
			@$scope.feedType = @_feedType

			@$scope.isFeedActive = (type, id) =>
				return @isFeedActive(type, id)
			
			@$scope.isShown = (type, id) =>
				return @isShown(type, id)

			@$scope.getUnreadCount = (type, id) =>
				return @getUnreadCount(type, id)

			@$scope.isShowAll = =>
				return @isShowAll()

			@$scope.loadFeed = (type, id) =>
				@loadFeed(type, id)

			@$scope.hasFeeds = (folderId) =>
				return @hasFeeds(folderId)

			@$scope.delete = (type, id) =>
				@delete(type, id)

			@$scope.markAllRead = (type, id) =>
				@markAllRead(type, id)

			@$scope.getFeedsOfFolder = (folderId) =>
				return @getFeedsOfFolder(folderId)

			@$scope.setShowAll = (showAll) =>
				@setShowAll(showAll)


		isFeedActive: (type, id) ->
			return type == @_active.getType() and id = @_active.getId()


		isShown: (type, id) ->
			if @isShowAll()
				return true
			else
				return @getUnreadCount(type, id) > 0


		isShowAll: ->
			return @_showAll.getShowAll()


		getUnreadCount: (type, id) ->
			# TODO: use polymorphism instead of switches
			switch type
				when @_feedType.Subscriptions
					count = @_feedModel.getUnreadCount()
				when @_feedType.Starred
					count = @_starredCount.getStarredCount()
				when @_feedType.Feed
					count = @_feedModel.getFeedUnreadCount(id)
				when @_feedType.Folder
					count = @_feedModel.getFolderUnreadCount(id)

			if count > 999
				count = '999+'

			return count


		loadFeed: (type, id) ->
			# TODO: use polymorphism instead of switches
			if type != @_active.getType() or id != @_active.getId()
				@_itemModel.clear()
				@_persistence.getItems(type, id, 0)
				@_active.handle({id: id, type: type})
			else
				lastModified = @_itemModel.getLastModified()
				@_persistence.getItems(type, id, 0, null, lastModified)


		hasFeeds: (folderId) ->
			return @_feedModel.getAllOfFolder(folderId).length


		delete: (type, id) ->
			# TODO: use polymorphism instead of switches
			switch type
				when @_feedType.Feed
					count = @_feedModel.removeById(id)
					@_persistence.deleteFeed(id)
				when @_feedType.Folder
					count = @_folderModel.removeById(id)
					@_persistence.deleteFolder(id)


		markAllRead: (type, id) ->
			# TODO: use polymorphism instead of switches
			switch type
				when @_feedType.Subscriptions
					for feed in @_feedModel.getAll()
						@markAllRead(@_feedType.Feed, feed.id)
				when @_feedType.Feed
					feed = @_feedModel.getById(id)
					if angular.isDefined(feed)
						feed.unreadCount = 0
						highestItemId = @_itemModel.getHighestId()
						@_persistence.setFeedRead(id, highestItemId)
				when @_feedType.Folder
					for feed in @_feedModel.getAllOfFolder(id)
						@markAllRead(@_feedType.Feed, feed.id)


		getFeedsOfFolder: (folderId) ->
			return @_feedModel.getAllOfFolder(folderId)


		setShowAll: (showAll) ->
			@_showAll.setShowAll(showAll)
			if showAll
				@_persistence.userSettingsReadShow()
			else
				@_persistence.userSettingsReadHide()


	return FeedController