//
//  MyLibraryViewModel.swift
//  SpotifyClone
//
//  Created by Gabriel on 10/20/21.
//

import Foundation

class MyLibraryViewModel: ObservableObject {
  var api = MyLibraryPageAPICalls()
  @Published var mainVM: MainViewModel

  @Published var isLoading = [Section:Bool]()
  @Published var mediaCollection = [Section:[SpotifyModel.MediaItem]]()

  @Published var currentSubPage: MyLibrarySubpage = .none
  @Published var pageHistory = [(subPage: MyLibrarySubpage, data: SpotifyModel.MediaItem, mediaDetailVM: MediaDetailViewModel)]()

  enum MyLibrarySubpage {
    case none
    case transitionScreen

    case tracksPreview
    case episodesPreview

    case playlistDetail
    case trackDetail
    case albumDetail
    case showDetail
    case artistDetail
    case episodeDetail
  }

  enum Section: String, CaseIterable {
    case userPlaylists
    case userArtists
    case userShows
  }

  init(mainViewModel: MainViewModel) {
    self.mainVM = mainViewModel

    for section in Section.allCases {
      isLoading[section] = true
      mediaCollection[section] = []
    }

    fetchMyLibraryData()
  }

  func fetchMyLibraryData() {
    for dictKey in isLoading.keys { isLoading[dictKey] = true }

    if mainVM.authKey != nil {
      let accessToken = mainVM.authKey!.accessToken

      getCurrentUserPlaylists(accessToken: accessToken)
      getCurrentUserArtists(accessToken: accessToken)
      getCurrentUserShows(accessToken: accessToken)
    }
  }



  // MARK: - API Calls

  func getCurrentUserPlaylists(accessToken: String) {
    api.getCurrentUserPlaylists(with: accessToken) { playlists in
      self.trimAndCommunicateResult(section: .userPlaylists, medias: playlists)
    }
  }

  func getCurrentUserArtists(accessToken: String) {
    api.getCurrentUserArtists(with: accessToken) { artists in
      self.trimAndCommunicateResult(section: .userArtists, medias: artists)
    }
  }

  func getCurrentUserShows(accessToken: String) {
    api.getCurrentUserShows(with: accessToken) { artists in
      self.trimAndCommunicateResult(section: .userShows, medias: artists)
    }
  }



  // MARK: - Auxiliary Functions

  func clean() {
    for section in Section.allCases {
      isLoading[section] = true
      mediaCollection[section] = []
    }
  }

  func trimAndCommunicateResult(section: Section, medias: [SpotifyModel.MediaItem]) {
    var noDuplicateMedias = [SpotifyModel.MediaItem]()
    var mediaIDs = [String]()

    // Sometimes the API returns more than one item with the same id, so we need to delete duplicates.
    for media in medias {
      if !mediaIDs.contains(media.id) {
        mediaIDs.append(media.id)
        noDuplicateMedias.append(media)
      }
    }
    mediaCollection[section] = noDuplicateMedias

    isLoading[section] = false
  }



  // MARK: - Non-api Related Functions

  func goToNoneSubpage() {
    pageHistory.removeAll()
    currentSubPage = .none
  }

  func goToPreviousPage() {

    // removes the current page
    pageHistory.removeLast()

    if pageHistory.isEmpty == false {
      changeSubpageTo(pageHistory.last!.subPage,
                      mediaDetailVM: pageHistory.last!.mediaDetailVM,
                      withData: pageHistory.last!.data)

      // removes the page that we just returned to
      pageHistory.removeLast()

    } else {
      goToNoneSubpage()
    }

  }

  func changeSubpageTo(_ subPage: MyLibrarySubpage,
                       mediaDetailVM: MediaDetailViewModel,
                       withData data: SpotifyModel.MediaItem) {

    pageHistory.append((subPage: subPage, data: data, mediaDetailVM: mediaDetailVM))

    currentSubPage = .transitionScreen

    // if we change the subpage right away it'll cause a crash
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      mediaDetailVM.clean()
      mediaDetailVM.mainItem = data
      mediaDetailVM.accessToken = self.mainVM.authKey!.accessToken
      mediaDetailVM.setVeryFirstImageInfoBasedOn(data.imageURL)
      self.currentSubPage = subPage
    }

  }

}
