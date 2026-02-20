import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]
    
    @State private var selectedBook: Book?
    @State private var showAddBook = false
    @State private var searchText = ""
    @State private var selectedFilter: BookStatus? = nil
    
    var filteredBooks: [Book] {
        let filtered = selectedFilter == nil ? books : books.filter { $0.status == selectedFilter }
        if searchText.isEmpty { return filtered }
        return filtered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // MARK: Sidebar
            VStack(spacing: 0) {
                // Logo
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Querio")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Read Less, Absorb More")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { showAddBook = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("새 책 추가")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider()
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "전체", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        ForEach(BookStatus.allCases, id: \.self) { status in
                            FilterChip(label: status.rawValue, isSelected: selectedFilter == status) {
                                selectedFilter = status
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                    TextField("제목, 저자 검색", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                Divider()
                
                // Book list
                if filteredBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("책을 추가해보세요")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredBooks, selection: $selectedBook) { book in
                        BookRow(book: book)
                            .tag(book)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 260)
            .background(Color(NSColor.windowBackgroundColor))
            
        } detail: {
            if let book = selectedBook {
                BookDetailView(book: book)
            } else {
                EmptyStateView()
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView { newBook in
                modelContext.insert(newBook)
                selectedBook = newBook
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Row
struct BookRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 10) {
            // Cover
            Group {
                if let urlString = book.coverImageURL, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.15))
                            .overlay(Text(String(book.title.prefix(1))).font(.system(size: 14, weight: .bold)).foregroundColor(.accentColor))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.15))
                        .overlay(Text(String(book.title.prefix(1))).font(.system(size: 14, weight: .bold)).foregroundColor(.accentColor))
                }
            }
            .frame(width: 32, height: 44)
            .cornerRadius(4)
            .clipped()
            
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: book.status.icon)
                        .font(.system(size: 13))
                    Text(book.status.rawValue)
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))
            Text("책을 선택하세요")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            Text("왼쪽에서 책을 선택하거나\n+ 버튼으로 새 책을 추가하세요")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
