import SwiftUI

struct MainTabView: View {
    enum Tab { case daily, weekly, meals, add }
    @State private var selectedTab: Tab = .daily

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { TodayView() }
                .tabItem { Label("Daily", systemImage: "sun.max") }
                .tag(Tab.daily)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { WeeklyView() }
                .tabItem { Label("Weekly", systemImage: "calendar") }
                .tag(Tab.weekly)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { MealsListView() }
                .tabItem { Label("Meals", systemImage: "fork.knife") }
                .tag(Tab.meals)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)

            NavigationStack { AddMealView(onSaved: { selectedTab = .meals }) }
                .tabItem { Label("Add", systemImage: "plus.circle") }
                .tag(Tab.add)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
